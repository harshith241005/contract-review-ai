"""
Fairness Engine Module
Calculates a fairness score (0-100) for car lease/loan contracts.
"""


def calculate_fairness_score(sla: dict) -> dict:
    """
    Calculate a fairness score (0–100) for a car lease/loan contract
    based on extracted SLA fields.
    
    Args:
        sla: Dictionary containing extracted SLA terms
    
    Returns:
        Dictionary with fairness_score (0-100), grade (A-F), and reasons
    """

    score = 100
    reasons = []
    positives = []

    # 1️⃣ Interest rate check (APR)
    apr = sla.get("apr_percent") or sla.get("interest_rate_apr")
    if apr:
        try:
            apr_val = float(str(apr).replace('%', ''))
            if apr_val > 15:
                score -= 25
                reasons.append(f"Very high interest rate ({apr_val}%)")
            elif apr_val > 12:
                score -= 20
                reasons.append(f"High interest rate ({apr_val}%)")
            elif apr_val > 8:
                score -= 10
                reasons.append(f"Above average interest rate ({apr_val}%)")
            elif apr_val < 5:
                positives.append(f"Excellent interest rate ({apr_val}%)")
        except ValueError:
            pass

    # 2️⃣ Early termination penalty
    penalties = sla.get("penalties", {})
    early_term = penalties.get("early_termination")
    if early_term and early_term not in [None, "No penalty", "Not specified", "null", ""]:
        score -= 15
        reasons.append("Early termination penalty is present")

    # 3️⃣ Late payment penalty
    late_penalty = penalties.get("late_payment") or sla.get("late_payment_penalty")
    if late_penalty:
        try:
            late_val = float(str(late_penalty).replace('$', '').replace(',', ''))
            if late_val > 50:
                score -= 10
                reasons.append(f"High late payment penalty (${late_val})")
            elif late_val > 25:
                score -= 5
                reasons.append("Moderate late payment penalty")
        except ValueError:
            pass

    # 4️⃣ Documentation fee
    fees = sla.get("fees", {})
    doc_fee = fees.get("documentation_fee")
    if doc_fee:
        try:
            doc_val = float(str(doc_fee).replace('$', '').replace(',', ''))
            if doc_val > 1000:
                score -= 15
                reasons.append(f"Excessive documentation fee (${doc_val})")
            elif doc_val > 500:
                score -= 10
                reasons.append(f"High documentation fee (${doc_val})")
            elif doc_val > 300:
                score -= 5
                reasons.append("Above average documentation fee")
        except ValueError:
            pass

    # 5️⃣ Acquisition fee (lease)
    acq_fee = fees.get("acquisition_fee")
    if acq_fee:
        try:
            acq_val = float(str(acq_fee).replace('$', '').replace(',', ''))
            if acq_val > 1000:
                score -= 10
                reasons.append(f"High acquisition fee (${acq_val})")
        except ValueError:
            pass

    # 6️⃣ Mileage allowance (lease)
    mileage = sla.get("mileage_allowance")
    if mileage:
        try:
            miles = int(str(mileage).replace(',', '').replace(' miles', ''))
            if miles < 10000:
                score -= 15
                reasons.append(f"Very low mileage allowance ({miles} miles/year)")
            elif miles < 12000:
                score -= 10
                reasons.append(f"Low mileage allowance ({miles} miles/year)")
            elif miles >= 15000:
                positives.append(f"Good mileage allowance ({miles} miles/year)")
        except ValueError:
            pass

    # 7️⃣ Overage charge per mile
    overage = sla.get("overage_charge_per_mile")
    if overage:
        try:
            overage_val = float(str(overage).replace('$', '').replace('/mile', ''))
            if overage_val > 0.25:
                score -= 10
                reasons.append(f"High overage charge (${overage_val}/mile)")
            elif overage_val > 0.20:
                score -= 5
                reasons.append("Above average overage charge")
            elif overage_val <= 0.15:
                positives.append(f"Low overage charge (${overage_val}/mile)")
        except ValueError:
            pass

    # 8️⃣ Check for red flags
    red_flags = sla.get("red_flags", [])
    if red_flags:
        num_flags = len(red_flags)
        score -= min(num_flags * 5, 20)  # Max -20 for red flags
        reasons.append(f"{num_flags} red flag(s) detected")
    else:
        positives.append("No red flags detected")

    # 9️⃣ Contract term length
    term = sla.get("term_months") or sla.get("lease_term")
    if term:
        try:
            term_val = int(str(term).replace(' months', ''))
            if term_val > 72:
                score -= 10
                reasons.append(f"Very long term ({term_val} months)")
            elif term_val > 60:
                score -= 5
                reasons.append(f"Long term ({term_val} months)")
        except ValueError:
            pass

    # 🔟 Total due at signing (lease)
    due_signing = sla.get("total_due_at_signing")
    if due_signing:
        try:
            due_val = float(str(due_signing).replace('$', '').replace(',', ''))
            if due_val > 5000:
                score -= 5
                reasons.append(f"High amount due at signing (${due_val})")
        except ValueError:
            pass

    # Ensure score boundaries
    score = max(0, min(score, 100))

    # Calculate grade
    if score >= 90:
        grade = "A"
        summary = "Excellent contract terms"
    elif score >= 80:
        grade = "B"
        summary = "Good contract with minor concerns"
    elif score >= 70:
        grade = "C"
        summary = "Average contract - room for negotiation"
    elif score >= 60:
        grade = "D"
        summary = "Below average - significant negotiation needed"
    else:
        grade = "F"
        summary = "Poor terms - consider walking away"

    return {
        "fairness_score": score,
        "grade": grade,
        "summary": summary,
        "concerns": reasons,
        "positives": positives,
        "reasons": reasons  # Keep for backward compatibility
    }


def compare_contracts(sla_list: list) -> dict:
    """
    Compare multiple contracts and rank them by fairness.
    
    Args:
        sla_list: List of SLA dictionaries with 'id' and 'sla' keys
    
    Returns:
        Dictionary with rankings and comparison details
    """
    results = []
    
    for item in sla_list:
        contract_id = item.get("id", "Unknown")
        sla = item.get("sla", {})
        fairness = calculate_fairness_score(sla)
        
        results.append({
            "contract_id": contract_id,
            "score": fairness["fairness_score"],
            "grade": fairness["grade"],
            "summary": fairness["summary"],
            "concerns": fairness["concerns"],
            "positives": fairness["positives"]
        })
    
    # Sort by score (highest first)
    results.sort(key=lambda x: x["score"], reverse=True)
    
    # Add rankings
    for i, result in enumerate(results, 1):
        result["rank"] = i
    
    return {
        "rankings": results,
        "best_contract": results[0] if results else None,
        "recommendation": f"Contract #{results[0]['contract_id']}" if results else "No contracts to compare"
    }