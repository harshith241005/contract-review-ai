"""
Negotiation Assistant Module
Generates negotiation tips and suggestions based on contract analysis.
"""


def generate_negotiation_points(sla: dict, fairness: dict) -> list:
    """
    Generate negotiation suggestions based on SLA and fairness score.
    
    Args:
        sla: Dictionary containing extracted SLA terms
        fairness: Dictionary containing fairness score and reasons
    
    Returns:
        List of negotiation point strings
    """
    points = []

    # Interest rate negotiation
    apr = sla.get("apr_percent") or sla.get("interest_rate_apr")
    if apr:
        try:
            apr_float = float(str(apr).replace('%', ''))
            if apr_float > 12:
                points.append(
                    f"HIGH PRIORITY: Your APR of {apr_float}% is above average. "
                    "Current market rates are around 5-8%. Ask for a rate reduction or "
                    "get pre-approved from a bank/credit union for leverage."
                )
            elif apr_float > 8:
                points.append(
                    f"MEDIUM PRIORITY: Your APR of {apr_float}% is slightly high. "
                    "Consider negotiating for a lower rate or shorter term."
                )
        except ValueError:
            pass

    # Documentation fee
    fees = sla.get("fees", {})
    doc_fee = fees.get("documentation_fee")
    if doc_fee:
        try:
            doc_amount = float(str(doc_fee).replace('$', '').replace(',', ''))
            if doc_amount > 500:
                points.append(
                    f"HIGH PRIORITY: Documentation fee of ${doc_amount} is excessive. "
                    "Request reduction or complete waiver - this is often negotiable."
                )
            else:
                points.append(
                    "LOW PRIORITY: Consider asking to waive or reduce the documentation fee."
                )
        except ValueError:
            points.append("Request reduction or waiver of the documentation fee.")

    # Acquisition fee (for leases)
    if fees.get("acquisition_fee"):
        points.append(
            "MEDIUM PRIORITY: Acquisition fees are sometimes negotiable. "
            "Ask if this can be reduced or rolled into the capitalized cost."
        )

    # Early termination penalty
    penalties = sla.get("penalties", {})
    early_term = penalties.get("early_termination")
    if early_term and early_term not in ["No penalty", "Not specified", None, "null"]:
        points.append(
            "HIGH PRIORITY: Early termination penalty exists. "
            "Negotiate for a shorter penalty period or lower fees. "
            "Ask about early payoff without penalty after a certain time."
        )

    # Late payment penalty
    late_payment = penalties.get("late_payment") or sla.get("late_payment_penalty")
    if late_payment:
        points.append(
            "MEDIUM PRIORITY: Negotiate for a grace period before late fees apply "
            "(typically 10-15 days is reasonable)."
        )

    # Mileage allowance (for leases)
    mileage = sla.get("mileage_allowance")
    if mileage:
        try:
            miles = int(str(mileage).replace(',', '').replace(' miles', ''))
            if miles < 12000:
                points.append(
                    f"HIGH PRIORITY: {miles} miles/year is below average. "
                    "Most drivers need 12,000-15,000 miles. "
                    "Negotiate higher mileage or lower overage charges."
                )
        except ValueError:
            pass

    # Overage charge
    overage = sla.get("overage_charge_per_mile")
    if overage:
        try:
            charge = float(str(overage).replace('$', '').replace('/mile', ''))
            if charge > 0.20:
                points.append(
                    f"MEDIUM PRIORITY: Overage charge of ${charge}/mile is high. "
                    "Industry average is $0.15-0.20. Negotiate this down."
                )
        except ValueError:
            pass

    # Down payment
    down = sla.get("down_payment")
    if down:
        points.append(
            "TIP: For leases, consider a lower down payment. "
            "If the car is totaled, you lose your down payment."
        )

    # Red flags from extraction
    red_flags = sla.get("red_flags", [])
    for flag in red_flags:
        if flag not in [f for p in points for f in p.split()]:
            points.append(f"RED FLAG: {flag}")

    # Overall fairness check
    score = fairness.get("fairness_score", 100)
    if score < 50:
        points.insert(0,
            "CRITICAL: This contract has a low fairness score. "
            "Consider walking away or demanding significant improvements."
        )
    elif score < 70:
        points.append(
            "MEDIUM PRIORITY: Overall contract fairness is below average. "
            "Ask the dealer to justify pricing and improve terms."
        )
    elif score >= 90:
        points.append(
            "LOW PRIORITY: Contract appears fair overall. "
            "You may still ask for minor concessions on fees."
        )

    # Default if no issues found
    if not points:
        points.append(
            "NO MAJOR ISSUES: This contract appears fair. "
            "You may still ask for small concessions like waiving fees "
            "or adding perks (free maintenance, accessories, etc.)."
        )

    return points


def generate_negotiation_email(sla: dict, points: list, customer_name: str = "[Your Name]") -> str:
    """
    Generate a professional negotiation email template.
    
    Args:
        sla: Dictionary containing extracted SLA terms
        points: List of negotiation points
        customer_name: Customer's name
    
    Returns:
        Email template string
    """
    vehicle = sla.get("vehicle_details", {})
    vehicle_name = f"{vehicle.get('year', '')} {vehicle.get('make', '')} {vehicle.get('model', '')}".strip()
    if not vehicle_name:
        vehicle_name = "[Vehicle Name]"
    
    email = f"""
Subject: Request for Terms Review - {vehicle_name}

Dear [Dealer/Finance Manager],

Thank you for providing the contract details for the {vehicle_name}. After careful review, I would like to discuss some terms before proceeding.

REQUESTED ADJUSTMENTS:
"""
    
    for i, point in enumerate(points[:5], 1):
        # Clean up the point for email
        clean_point = (
            point
            .replace("HIGH PRIORITY: ", "")
            .replace("MEDIUM PRIORITY: ", "")
            .replace("LOW PRIORITY: ", "")
            .replace("TIP: ", "")
            .replace("RED FLAG: ", "")
            .replace("CRITICAL: ", "")
            .replace("NO MAJOR ISSUES: ", "")
            .replace("🔴 HIGH PRIORITY: ", "")
            .replace("🟡 MEDIUM PRIORITY: ", "")
            .replace("🟢 ", "")
            .replace("💡 TIP: ", "")
            .replace("⚠️ RED FLAG: ", "")
            .replace("🚨 CRITICAL: ", "")
            .replace("✅ ", "")
        )
        email += f"\n{i}. {clean_point}"
    
    email += f"""

I am a serious buyer and am ready to finalize the deal once we can agree on improved terms. I have been researching market rates and comparable offers, and believe these adjustments are reasonable.

Please let me know your thoughts at your earliest convenience.

Best regards,
{customer_name}
[Phone Number]
[Email]
"""
    
    return email


def generate_questions_list() -> list:
    """
    Generate a list of important questions to ask the dealer.
    
    Returns:
        List of question strings
    """
    return [
        # Pricing Questions
        "What is the out-the-door price including ALL fees and taxes?",
        "Are there any dealer add-ons or accessories I can remove?",
        "Is there room for negotiation on the vehicle price?",
        "Are there any manufacturer incentives or rebates available?",
        
        # Financing Questions
        "What APR am I approved for? What determines this rate?",
        "Can you match a rate from my bank or credit union?",
        "Are there any special financing promotions available?",
        "What is the total cost of the loan over its lifetime?",
        
        # Loan Terms Questions
        "Is there a prepayment penalty?",
        "Can I make extra payments toward the principal?",
        "What happens if I want to refinance later?",
        "What are the consequences of a late payment?",
        
        # Lease-Specific Questions
        "What is the money factor (lease interest rate)?",
        "What is the residual value at lease end?",
        "Can I negotiate the mileage allowance?",
        "What are the wear-and-tear guidelines?",
        "What is the process for returning the vehicle?",
        
        # General Questions
        "What warranties are included?",
        "Is GAP insurance included or recommended?",
        "What are my options at the end of the term?",
        "Can I see an itemized breakdown of all charges?",
    ]
