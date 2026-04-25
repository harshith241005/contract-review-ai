"""
spaCy-based NLP enrichment for contract extraction.

This module uses lightweight tokenization, sentence segmentation, and keyword
matching to find the most relevant sentence windows for important contract
fields. It fills only missing values and leaves existing regex-extracted values
untouched.
"""

from __future__ import annotations

import re
from typing import Dict, List

import spacy
from spacy.matcher import Matcher


def _init_nlp_and_matcher():
    try:
        nlp = spacy.load("en_core_web_sm")
    except Exception:
        nlp = spacy.blank("en")
        if "sentencizer" not in nlp.pipe_names:
            nlp.add_pipe("sentencizer")

    matcher = Matcher(nlp.vocab)

    matcher.add("APR", [[{"LOWER": {"IN": ["apr", "interest", "rate"]}}]])
    matcher.add("MONTHLY_PAYMENT", [[{"LOWER": "monthly"}, {"LOWER": "payment"}]])
    matcher.add("TERM", [[{"LOWER": {"IN": ["term", "tenure", "months", "lease"]}}]])
    matcher.add("DOWN_PAYMENT", [[{"LOWER": "down"}, {"LOWER": "payment"}]])
    matcher.add("DOC_FEE", [[{"LOWER": "documentation"}, {"LOWER": "fee"}]])
    matcher.add("EARLY_TERMINATION", [[{"LOWER": "early"}, {"LOWER": "termination"}]])
    matcher.add("MILEAGE", [[{"LOWER": {"IN": ["mileage", "mile", "miles"]}}]])
    matcher.add("OVERAGE", [[{"LOWER": {"IN": ["overage", "over", "mileage"]}}]])

    return nlp, matcher


_NLP, _MATCHER = _init_nlp_and_matcher()


def _extract_first(patterns: List[str], text: str) -> str | None:
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return match.group(1)
    return None


def _collect_context_sentences(text: str) -> Dict[str, str]:
    doc = _NLP(text)
    contexts: Dict[str, List[str]] = {
        "APR": [],
        "MONTHLY_PAYMENT": [],
        "TERM": [],
        "DOWN_PAYMENT": [],
        "DOC_FEE": [],
        "EARLY_TERMINATION": [],
        "MILEAGE": [],
        "OVERAGE": [],
    }

    for match_id, start, _ in _MATCHER(doc):
        label = doc.vocab.strings[match_id]
        sent = doc[start].sent.text.strip()
        if sent and sent not in contexts[label]:
            contexts[label].append(sent)

    return {k: " ".join(v) for k, v in contexts.items()}


def _is_missing(value) -> bool:
    if value is None:
        return True
    if isinstance(value, str):
        return value.strip().lower() in {"", "none", "null", "n/a", "na", "not specified"}
    return False


def enrich_contract_fields_with_spacy(contract_text: str, extracted: dict) -> dict:
    """Fill missing extracted fields by using spaCy sentence-level context."""
    if not contract_text:
        return extracted

    contexts = _collect_context_sentences(contract_text)

    if _is_missing(extracted.get("apr_percent")):
        extracted["apr_percent"] = _extract_first(
            [
                r"(?:apr|interest\s*rate)[^0-9]{0,15}(\d+(?:\.\d+)?)\s*%",
                r"(\d+(?:\.\d+)?)\s*%",
            ],
            contexts.get("APR", ""),
        )

    if _is_missing(extracted.get("monthly_payment")):
        extracted["monthly_payment"] = _extract_first(
            [
                r"monthly\s*payment[^0-9]{0,15}\$?\s*(\d+(?:\.\d{1,2})?)",
                r"\$\s*(\d+(?:\.\d{1,2})?)",
            ],
            contexts.get("MONTHLY_PAYMENT", ""),
        )

    if _is_missing(extracted.get("term_months")):
        extracted["term_months"] = _extract_first(
            [
                r"(?:term|tenure|lease\s*term)[^0-9]{0,15}(\d{1,3})\s*(?:months?|mos?)",
                r"(\d{1,3})\s*(?:months?|mos?)",
            ],
            contexts.get("TERM", ""),
        )

    if _is_missing(extracted.get("down_payment")):
        extracted["down_payment"] = _extract_first(
            [
                r"down\s*payment[^0-9]{0,15}\$?\s*(\d+(?:\.\d{1,2})?)",
                r"\$\s*(\d+(?:\.\d{1,2})?)",
            ],
            contexts.get("DOWN_PAYMENT", ""),
        )

    fees = extracted.setdefault("fees", {})
    if _is_missing(fees.get("documentation_fee")):
        fees["documentation_fee"] = _extract_first(
            [
                r"documentation\s*fee[^0-9]{0,15}\$?\s*(\d+(?:\.\d{1,2})?)",
                r"doc\s*fee[^0-9]{0,15}\$?\s*(\d+(?:\.\d{1,2})?)",
            ],
            contexts.get("DOC_FEE", ""),
        )

    penalties = extracted.setdefault("penalties", {})
    if _is_missing(penalties.get("early_termination")):
        early_text = contexts.get("EARLY_TERMINATION", "")
        if re.search(r"without\s+penalty", early_text, re.IGNORECASE):
            penalties["early_termination"] = "No penalty"
        else:
            penalties["early_termination"] = _extract_first(
                [r"early\s*termination[^0-9]{0,20}\$?\s*(\d+(?:\.\d{1,2})?)"],
                early_text,
            )

    if _is_missing(extracted.get("mileage_allowance")):
        extracted["mileage_allowance"] = _extract_first(
            [
                r"mileage\s*(?:allowance)?[^0-9]{0,20}(\d{4,6})\s*miles?",
                r"(\d{4,6})\s*miles?",
            ],
            contexts.get("MILEAGE", ""),
        )

    if _is_missing(extracted.get("overage_charge_per_mile")):
        extracted["overage_charge_per_mile"] = _extract_first(
            [
                r"(?:overage|over\s*mileage)[^0-9]{0,20}\$?\s*(\d+(?:\.\d{1,2})?)",
                r"\$?\s*(\d+(?:\.\d{1,2})?)\s*(?:/\s*mile|per\s*mile)",
            ],
            contexts.get("OVERAGE", ""),
        )

    return extracted
