// SLA Model - Represents extracted contract terms

class SlaData {
  final Map<String, dynamic> rawData;
  final String? contractType;
  final String? interestRateApr;
  final String? leaseTermMonths;
  final String? monthlyPayment;
  final String? downPayment;
  final String? financeAmount;
  final String? totalDueAtSigning;
  final String? totalCost;
  final String? residualValue;
  final String? mileageAllowance;
  final String? overageChargePerMile;
  final String? earlyTerminationClause;
  final String? purchaseOptionPrice;
  final String? maintenanceResponsibility;
  final String? warrantyCoverage;
  final String? insuranceRequirements;
  final String? latePaymentPenalty;
  final Map<String, String?> fees;
  final Map<String, String?> penalties;
  final String? extractionMethod;
  final List<String> redFlags;
  final int? contractFairnessScore;

  SlaData({
    this.rawData = const {},
    this.contractType,
    this.interestRateApr,
    this.leaseTermMonths,
    this.monthlyPayment,
    this.downPayment,
    this.financeAmount,
    this.totalDueAtSigning,
    this.totalCost,
    this.residualValue,
    this.mileageAllowance,
    this.overageChargePerMile,
    this.earlyTerminationClause,
    this.purchaseOptionPrice,
    this.maintenanceResponsibility,
    this.warrantyCoverage,
    this.insuranceRequirements,
    this.latePaymentPenalty,
    this.fees = const {},
    this.penalties = const {},
    this.extractionMethod,
    this.redFlags = const [],
    this.contractFairnessScore,
  });

  factory SlaData.fromJson(Map<String, dynamic> json) {
    final penalties = (json['penalties'] as Map<String, dynamic>?) ?? const {};
    final fees = (json['fees'] as Map<String, dynamic>?) ?? const {};
    final raw = Map<String, dynamic>.from(json);

    return SlaData(
      rawData: raw,
      contractType: json['contract_type']?.toString() ?? json['loan_type']?.toString(),
      interestRateApr: json['interest_rate_apr']?.toString() ?? json['apr_percent']?.toString(),
      leaseTermMonths: json['lease_term_months']?.toString() ?? json['term_months']?.toString() ?? json['contract_duration_months']?.toString(),
      monthlyPayment: json['monthly_payment']?.toString(),
      downPayment: json['down_payment']?.toString(),
      financeAmount: json['finance_amount']?.toString(),
      totalDueAtSigning: json['total_due_at_signing']?.toString(),
      totalCost: json['total_cost']?.toString(),
      residualValue: json['residual_value']?.toString(),
      mileageAllowance: json['mileage_allowance']?.toString(),
      overageChargePerMile: json['overage_charge_per_mile']?.toString(),
      earlyTerminationClause:
          json['early_termination_clause']?.toString() ?? penalties['early_termination']?.toString(),
      purchaseOptionPrice: json['purchase_option_price']?.toString(),
      maintenanceResponsibility: json['maintenance_responsibility']?.toString(),
      warrantyCoverage: json['warranty_coverage']?.toString(),
      insuranceRequirements: json['insurance_requirements']?.toString(),
      latePaymentPenalty:
          json['late_payment_penalty']?.toString() ?? penalties['late_payment']?.toString(),
      fees: {
        'documentation_fee': fees['documentation_fee']?.toString(),
        'acquisition_fee': fees['acquisition_fee']?.toString(),
        'registration_fee': fees['registration_fee']?.toString(),
        'processing_fee': fees['processing_fee']?.toString(),
        'dealer_prep_fee': fees['dealer_prep_fee']?.toString(),
        'other_fees': fees['other_fees']?.toString(),
      },
      penalties: {
        'late_payment': penalties['late_payment']?.toString(),
        'early_termination': penalties['early_termination']?.toString(),
        'over_mileage': penalties['over_mileage']?.toString(),
      },
      extractionMethod: json['extraction_method']?.toString(),
      redFlags: (json['red_flags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      contractFairnessScore: json['contract_fairness_score'] != null 
          ? int.tryParse(json['contract_fairness_score'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...rawData,
      'contract_type': contractType,
      'interest_rate_apr': interestRateApr,
      'lease_term_months': leaseTermMonths,
      'monthly_payment': monthlyPayment,
      'down_payment': downPayment,
      'finance_amount': financeAmount,
      'total_due_at_signing': totalDueAtSigning,
      'total_cost': totalCost,
      'residual_value': residualValue,
      'mileage_allowance': mileageAllowance,
      'overage_charge_per_mile': overageChargePerMile,
      'early_termination_clause': earlyTerminationClause,
      'purchase_option_price': purchaseOptionPrice,
      'maintenance_responsibility': maintenanceResponsibility,
      'warranty_coverage': warrantyCoverage,
      'insurance_requirements': insuranceRequirements,
      'late_payment_penalty': latePaymentPenalty,
      'fees': fees,
      'penalties': penalties,
      'extraction_method': extractionMethod,
      'red_flags': redFlags,
      'contract_fairness_score': contractFairnessScore,
    };
  }

  List<MapEntry<String, String>> get allExtractedKeyValuePairs {
    final pairs = <MapEntry<String, String>>[];

    bool isMeaningfulValue(String value) {
      final normalized = value.trim().toLowerCase();
      return normalized.isNotEmpty &&
          normalized != 'n/a' &&
          normalized != 'na' &&
          normalized != 'null' &&
          normalized != 'none' &&
          normalized != 'not applicable';
    }

    bool shouldSkipPath(String path) {
      final p = path.toLowerCase();
      if (p.isEmpty) return true;
      if (p.startsWith('vehicle_details.raw_data')) return true;
      if (p.startsWith('negotiation_points')) return true;
      return false;
    }

    void flatten(dynamic value, String prefix) {
      if (shouldSkipPath(prefix)) {
        return;
      }

      if (value is Map) {
        final keys = value.keys.map((k) => k.toString()).toList()..sort();
        for (final key in keys) {
          final nestedValue = value[key];
          final nestedPrefix = prefix.isEmpty ? key : '$prefix.$key';
          if (shouldSkipPath(nestedPrefix)) {
            continue;
          }
          flatten(nestedValue, nestedPrefix);
        }
        return;
      }

      if (value is List) {
        if (value.isEmpty) {
          return;
        }

        // Avoid exploding the UI with huge list payloads.
        if (value.length > 8 || value.any((e) => e is Map || e is List)) {
          pairs.add(MapEntry(prefix, '${value.length} items'));
          return;
        }

        for (var i = 0; i < value.length; i++) {
          flatten(value[i], '$prefix[$i]');
        }
        return;
      }

      final rendered = value == null ? 'N/A' : value.toString();
      if (!isMeaningfulValue(rendered)) {
        return;
      }
      pairs.add(MapEntry(prefix, rendered));
    }

    flatten(rawData, '');
    pairs.sort((a, b) => a.key.compareTo(b.key));
    return pairs;
  }

  // Get all terms as a list for display
  List<SlaTermItem> get allTerms {
    return [
      SlaTermItem('Contract Type', contractType, 'document'),
      SlaTermItem('Interest Rate (APR)', interestRateApr != null ? '$interestRateApr%' : null, 'percent'),
      SlaTermItem('Lease Term', leaseTermMonths != null ? '$leaseTermMonths months' : null, 'calendar'),
      SlaTermItem('Monthly Payment', monthlyPayment != null ? '\$$monthlyPayment' : null, 'dollar'),
      SlaTermItem('Down Payment', downPayment != null ? '\$$downPayment' : null, 'dollar'),
      SlaTermItem('Amount Financed', financeAmount != null ? '\$$financeAmount' : null, 'dollar'),
      SlaTermItem('Total Due At Signing', totalDueAtSigning != null ? '\$$totalDueAtSigning' : null, 'dollar'),
      SlaTermItem('Total Cost', totalCost != null ? '\$$totalCost' : null, 'dollar'),
      SlaTermItem('Residual Value', residualValue != null ? '\$$residualValue' : null, 'dollar'),
      SlaTermItem('Mileage Allowance', mileageAllowance != null ? '$mileageAllowance miles' : null, 'car'),
      SlaTermItem('Overage Charge', overageChargePerMile != null ? '\$$overageChargePerMile/mile' : null, 'warning'),
      SlaTermItem('Early Termination', earlyTerminationClause, 'alert'),
      SlaTermItem('Purchase Option', purchaseOptionPrice != null ? '\$$purchaseOptionPrice' : null, 'shopping'),
      SlaTermItem('Maintenance', maintenanceResponsibility, 'tools'),
      SlaTermItem('Warranty', warrantyCoverage, 'shield'),
      SlaTermItem('Insurance', insuranceRequirements, 'insurance'),
      SlaTermItem('Late Payment Penalty', latePaymentPenalty, 'warning'),
    ];
  }
}

class SlaTermItem {
  final String label;
  final String? value;
  final String iconType;

  SlaTermItem(this.label, this.value, this.iconType);

  bool get hasValue => value != null && value!.isNotEmpty && value != 'null';
}
