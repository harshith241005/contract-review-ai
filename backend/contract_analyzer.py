import re
from datetime import datetime
from backend.vin_service import get_vehicle_details
from backend.nlp_extractor import enrich_contract_fields_with_spacy


# ---------------- HELPER FUNCTIONS ---------------- #

def clean_text(text: str) -> str:
    text = text.replace(",", "")
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def extract_amount(patterns, text):
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return match.group(1)
    return None


def extract_amount_from_sources(patterns, *sources):
    for source in sources:
        if not source:
            continue
        value = extract_amount(patterns, source)
        if value:
            return value
    return None


def normalize_numeric(value: str):
    if value is None:
        return None
    cleaned = str(value).strip().replace("$", "").replace(",", "")
    return cleaned if cleaned else None


def calculate_term_from_dates(text):
    match = re.search(
        r"beginning on (\w+ \d{4}).*?ending on (\w+ \d{4})",
        text,
        re.IGNORECASE
    )
    if match:
        start = datetime.strptime(match.group(1), "%B %Y")
        end = datetime.strptime(match.group(2), "%B %Y")
        return (end.year - start.year) * 12 + (end.month - start.month)
    return None


def extract_vin(text: str):
    vin_pattern = r"\b[A-HJ-NPR-Z0-9]{17}\b"
    match = re.search(vin_pattern, text)
    return match.group(0) if match else None


def extract_vehicle_from_contract_text(text: str):
    return {
        "year": extract_amount_from_sources(
            [
                r"\byear\s*[:\-]\s*(\d{4})",
                r"\bmodel\s*year\s*[:\-]\s*(\d{4})"
            ],
            text
        ),
        "make": extract_amount_from_sources(
            [
                r"\bmake\s*[:\-]\s*([A-Za-z][A-Za-z0-9\- ]{1,30})",
            ],
            text
        ),
        "model": extract_amount_from_sources(
            [
                r"\bmodel\s*[:\-]\s*([A-Za-z0-9\- ]{1,40})",
            ],
            text
        ),
    }


def clean_vehicle_value(value: str):
    if value is None:
        return None
    cleaned = re.sub(r"\s+", " ", str(value)).strip(" .:-")
    return cleaned if cleaned else None


# ---------------- MAIN ANALYZER ---------------- #

def analyze_contract(contract_text: str) -> dict:
    if not contract_text or len(contract_text) < 50:
        raise ValueError("Contract text too short")

    text = clean_text(contract_text)
    raw_text = contract_text

    # ---------------- LOAN / LEASE TYPE ---------------- #
    if re.search(r"lease", text, re.I):
        loan_type = "Vehicle Lease"
    elif re.search(r"loan|finance|emi", text, re.I):
        loan_type = "Car Loan"
    else:
        loan_type = None

    # ---------------- APR / INTEREST ---------------- #
    apr_percent = extract_amount(
        [
            r"annual\s+percentage\s+rate\s*\(\s*apr\s*\)\s*[:\-]?\s*\$?\s*(\d+\.?\d*)\s*%",
            r"APR\s*[:\-]?\s*(\d+\.?\d*)%",
            r"annual\s+percentage\s+rate\s*\(\s*apr\s*\)\s*[:\-]?\s*(\d+\.?\d*)%",
            r"annual\s+percentage\s+rate\s*[:\-]?\s*(\d+\.?\d*)%",
            r"interest\s*rate.*?(\d+\.?\d*)%",
            r"rate\s+of\s+interest.*?(\d+\.?\d*)%",
            r"interest\s*@\s*(\d+\.?\d*)%"
        ],
        raw_text
    )

    if not apr_percent:
        apr_percent = extract_amount(
            [
                r"APR\s*[:\-]?\s*(\d+\.?\d*)%",
                r"annual\s+percentage\s+rate\s*\(\s*apr\s*\)\s*[:\-]?\s*(\d+\.?\d*)%",
                r"annual\s+percentage\s+rate\s*[:\-]?\s*(\d+\.?\d*)%",
            ],
            text
        )

    # ---------------- MONTHLY PAYMENT ---------------- #
    monthly_payment = extract_amount_from_sources(
        [
            r"monthly\s*payment\s*[:\-]?\s*(?:\$|Rs\.?\s*)?\s*([0-9][0-9,]*(?:\.\d{1,2})?)",
            r"monthly\s*payment[^0-9]{0,40}([0-9][0-9,]*(?:\.\d{1,2})?)",
            r"monthly\s+installments?\s+of\s*(?:\$|Rs\.?\s*)?\s*([0-9][0-9,]*(?:\.\d{1,2})?)",
            r"monthly\s+installments?[^0-9]{0,40}([0-9][0-9,]*(?:\.\d{1,2})?)",
            r"payment\s+amount[^0-9]{0,40}([0-9][0-9,]*(?:\.\d{1,2})?)",
            r"EMI\s*(?:\$|Rs\.?\s*)?\s*([0-9][0-9,]*(?:\.\d{1,2})?)"
        ],
        raw_text,
        text
    )

    # ---------------- TERM / TENURE ---------------- #
    term_months = extract_amount_from_sources(
        [
            r"\bterm\s*[:\-]?\s*(\d+)\s*(?:months?|mos?)",
            r"term\s*[:\-]?\s*(\d+)\s*(?:months?|mos?)",
            r"lease\s*term\s*[:\-]?\s*(\d+)\s*(?:months?|mos?)",
            r"loan\s*term\s*[:\-]?\s*(\d+)\s*(?:months?|mos?)",
            r"(\d+)\s*monthly\s*installments?",
            r"(\d+)\s*months",
            r"(\d+)\s*mos\b",
            r"tenure\s*[:\-]?\s*(\d+)"
        ],
        raw_text,
        text
    )

    if not term_months:
        term_months = calculate_term_from_dates(text)

    # ---------------- DOWN PAYMENT ---------------- #
    down_payment = extract_amount_from_sources(
        [
            r"down\s*payment\s*[:\-]?\s*\$?\s*(\d+(?:\.\d{1,2})?)",
            r"down\s*payment[^0-9]{0,40}(\d+(?:\.\d{1,2})?)",
            r"initial\s+payment[^0-9]{0,40}(\d+(?:\.\d{1,2})?)",
            r"advance[^0-9]{0,40}(\d+(?:\.\d{1,2})?)"
        ],
        raw_text,
        text
    )

    # ---------------- FINANCE / LOAN AMOUNT ---------------- #
    finance_amount = extract_amount_from_sources(
        [
            r"total\s+amount\s+financed\s*[:\-]?\s*\$?\s*(\d+(?:\.\d{1,2})?)",
            r"principal\s+amount[^0-9]{0,40}(\d+(?:\.\d{1,2})?)",
            r"amount\s+financed[^0-9]{0,40}(\d+(?:\.\d{1,2})?)",
            r"loan\s+amount[^0-9]{0,40}(\d+(?:\.\d{1,2})?)",
            r"loan\s+of\s*Rs\.?\s*([0-9][0-9,]*(?:\.\d{1,2})?)",
            r"Loan Amount:\s*Rs\.?\s*([0-9][0-9,]*(?:\.\d{1,2})?)",
            r"loan amount\s*Rs\.?\s*([0-9][0-9,]*(?:\.\d{1,2})?)",
            r"amount\s+financed\s*([0-9][0-9,]*(?:\.\d{1,2})?)",
            r"principal\s+amount\s*([0-9][0-9,]*(?:\.\d{1,2})?)"
        ],
        raw_text,
        text
    )

    total_due_at_signing = extract_amount_from_sources(
        [
            r"total\s+due\s+at\s+signing\s*[:\-]?\s*\$?\s*(\d+(?:\.\d{1,2})?)",
            r"amount\s+due\s+at\s+signing\s*[:\-]?\s*\$?\s*(\d+(?:\.\d{1,2})?)",
        ],
        raw_text,
        text,
    )

    total_cost = extract_amount_from_sources(
        [
            r"total\s+cost\s*[:\-]?\s*\$?\s*(\d+(?:\.\d{1,2})?)",
            r"total\s+of\s+payments\s*[:\-]?\s*\$?\s*(\d+(?:\.\d{1,2})?)",
        ],
        raw_text,
        text,
    )

    residual_value = extract_amount_from_sources(
        [
            r"residual\s+value\s*[:\-]?\s*\$?\s*(\d+(?:\.\d{1,2})?)",
            r"lease\s+end\s+value\s*[:\-]?\s*\$?\s*(\d+(?:\.\d{1,2})?)",
        ],
        raw_text,
        text,
    )

    purchase_option_price = extract_amount_from_sources(
        [
            r"purchase\s+option\s+(?:price|fee)\s*[:\-]?\s*\$?\s*(\d+(?:\.\d{1,2})?)",
            r"buyout\s+price\s*[:\-]?\s*\$?\s*(\d+(?:\.\d{1,2})?)",
        ],
        raw_text,
        text,
    )

    mileage_allowance = extract_amount_from_sources(
        [
            r"mileage\s+allowance\s*[:\-]?\s*(\d+)\s*miles?",
            r"annual\s+mileage\s+allowance\s*[:\-]?\s*(\d+)\s*miles?",
        ],
        raw_text,
        text,
    )

    overage_charge_per_mile = extract_amount_from_sources(
        [
            r"over\s+mileage\s+charge\s*[:\-]?\s*\$?\s*(\d+(?:\.\d{1,2})?)",
            r"overage\s+charge\s+(?:per\s+mile)?\s*[:\-]?\s*\$?\s*(\d+(?:\.\d{1,2})?)",
        ],
        raw_text,
        text,
    )

    # ---------------- FEES ---------------- #
    fees = {
        "documentation_fee": extract_amount(
            [r"documentation\s*fee[^0-9]{0,40}(\d+(?:\.\d{1,2})?)"], raw_text
        ),
        "registration_fee": extract_amount(
            [r"registration\s*fee[^0-9]{0,40}(\d+(?:\.\d{1,2})?)"], raw_text
        ),
        "acquisition_fee": extract_amount(
            [r"acquisition\s*fee[^0-9]{0,40}(\d+(?:\.\d{1,2})?)"], raw_text
        ),
        "other_fees": extract_amount(
            [
                r"processing\s*fee[^0-9]{0,40}(\d+(?:\.\d{1,2})?)",
                r"dealer\s*fee[^0-9]{0,40}(\d+(?:\.\d{1,2})?)"
            ],
            raw_text
        )
    }

    # ---------------- PENALTIES ---------------- #
    penalties = {
        "late_payment": extract_amount(
            [
                r"late\s*payment\s*(?:penalty|fee)?[^0-9]{0,40}(\d+(?:\.\d{1,2})?)",
                r"late\s*fee[^0-9]{0,40}(\d+(?:\.\d{1,2})?)"
            ],
            raw_text
        ),
        "early_termination": "No penalty"
        if re.search(r"without penalty", text, re.I)
        else extract_amount(
            [
                r"early\s*termination(?:\s*penalty|\s*fee)?[^0-9]{0,40}(\d+(?:\.\d{1,2})?)",
                r"termination\s*fee[^0-9]{0,40}(\d+(?:\.\d{1,2})?)"
            ],
            raw_text
        ),
        "over_mileage": extract_amount(
            [
                r"over\s*mileage.*?\$?\s*(\d+(?:\.\d{1,2})?)",
                r"overage\s*charge.*?\$?\s*(\d+(?:\.\d{1,2})?)"
            ],
            raw_text
        )
    }

    # Fill only missing fields using spaCy sentence-level NLP context.
    nlp_enriched = enrich_contract_fields_with_spacy(
        raw_text,
        {
            "apr_percent": apr_percent,
            "monthly_payment": monthly_payment,
            "term_months": term_months,
            "down_payment": down_payment,
            "fees": fees,
            "penalties": penalties,
            "mileage_allowance": mileage_allowance,
            "overage_charge_per_mile": overage_charge_per_mile,
        },
    )
    apr_percent = nlp_enriched.get("apr_percent", apr_percent)
    monthly_payment = nlp_enriched.get("monthly_payment", monthly_payment)
    term_months = nlp_enriched.get("term_months", term_months)
    down_payment = nlp_enriched.get("down_payment", down_payment)
    fees = nlp_enriched.get("fees", fees)
    penalties = nlp_enriched.get("penalties", penalties)
    mileage_allowance = nlp_enriched.get("mileage_allowance", mileage_allowance)
    overage_charge_per_mile = nlp_enriched.get("overage_charge_per_mile", overage_charge_per_mile)

    # ---------------- RED FLAGS ---------------- #
    red_flags = []

    if penalties["early_termination"] and penalties["early_termination"] != "No penalty":
        red_flags.append("Early termination penalty is present")

    if apr_percent:
        try:
            if float(apr_percent) > 12:
                red_flags.append("High interest rate")
        except:
            pass

    # ---------------- NEGOTIATION POINTS ---------------- #
    negotiation_points = []

    if apr_percent:
        negotiation_points.append("Ask for lower interest rate")

    if fees["documentation_fee"]:
        negotiation_points.append("Negotiate documentation fee")

    if penalties["early_termination"] and penalties["early_termination"] != "No penalty":
        negotiation_points.append("Reduce early termination penalty")

    # ---------------- VIN EXTRACTION ---------------- #
    vin = extract_vin(text)
    vehicle_from_text = extract_vehicle_from_contract_text(raw_text)
    vehicle_details = {}
    if vin:
        try:
            vehicle_details = get_vehicle_details(vin)
        except Exception:
            vehicle_details = {}

    # Merge extracted contract vehicle lines as fallback/complement.
    if not isinstance(vehicle_details, dict):
        vehicle_details = {}
    for key in ["year", "make", "model"]:
        if not vehicle_details.get(key) and vehicle_from_text.get(key):
            vehicle_details[key] = clean_vehicle_value(vehicle_from_text[key])

    # Normalize numeric-like fields for consistent frontend rendering.
    apr_percent = normalize_numeric(apr_percent)
    monthly_payment = normalize_numeric(monthly_payment)
    term_months = normalize_numeric(term_months)
    down_payment = normalize_numeric(down_payment)
    finance_amount = normalize_numeric(finance_amount)
    total_due_at_signing = normalize_numeric(total_due_at_signing)
    total_cost = normalize_numeric(total_cost)
    residual_value = normalize_numeric(residual_value)
    purchase_option_price = normalize_numeric(purchase_option_price)
    mileage_allowance = normalize_numeric(mileage_allowance)
    overage_charge_per_mile = normalize_numeric(overage_charge_per_mile)

    for k, v in list(fees.items()):
        fees[k] = normalize_numeric(v)
    for k, v in list(penalties.items()):
        if v != "No penalty":
            penalties[k] = normalize_numeric(v)

    # ---------------- FINAL JSON ---------------- #
    return {
        "vin": vin,
        "vehicle_details": vehicle_details,
        "loan_type": loan_type,
        "contract_type": loan_type,
        "apr_percent": apr_percent,
        "interest_rate_apr": apr_percent,
        "monthly_payment": monthly_payment,
        "term_months": term_months,
        "lease_term_months": term_months,
        "down_payment": down_payment,
        "finance_amount": finance_amount,
        "total_due_at_signing": total_due_at_signing,
        "total_cost": total_cost,
        "residual_value": residual_value,
        "purchase_option_price": purchase_option_price,
        "mileage_allowance": mileage_allowance,
        "overage_charge_per_mile": overage_charge_per_mile,
        "fees": fees,
        "penalties": penalties,
        "late_payment_penalty": penalties.get("late_payment"),
        "early_termination_clause": penalties.get("early_termination"),
        "red_flags": red_flags,
        "negotiation_points": negotiation_points,
        "extraction_method": "regex+spacy"
    }
