// Contract Model - Represents a full contract with analysis

import 'sla_data.dart';

class Contract {
  final int id;
  final String fileName;
  final DateTime createdAt;
  final SlaData? slaData;
  final VehicleInfo? vehicleInfo;
  final FairnessScore? fairnessScore;

  Contract({
    required this.id,
    required this.fileName,
    required this.createdAt,
    this.slaData,
    this.vehicleInfo,
    this.fairnessScore,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    final slaJson = json['sla'] as Map<String, dynamic>?;
    final vehicleInfoJson = json['vehicle_info'] as Map<String, dynamic>?;
    final vehicleDetailsJson = slaJson != null
        ? slaJson['vehicle_details'] as Map<String, dynamic>?
        : null;

    return Contract(
      id: json['contract_id'] ?? json['id'] ?? 0,
      fileName: json['file_name'] ?? json['fileName'] ?? 'Unknown',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      slaData: slaJson != null ? SlaData.fromJson(slaJson) : null,
      vehicleInfo: vehicleInfoJson != null
          ? VehicleInfo.fromJson(vehicleInfoJson)
          : (vehicleDetailsJson != null ? VehicleInfo.fromJson(vehicleDetailsJson) : null),
      fairnessScore: json['fairness'] != null
          ? FairnessScore.fromJson(json['fairness'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'created_at': createdAt.toIso8601String(),
      'sla': slaData?.toJson(),
      'vehicle_info': vehicleInfo?.toJson(),
      'fairness': fairnessScore?.toJson(),
    };
  }
}

class VehicleInfo {
  final String? vin;
  final String? make;
  final String? model;
  final String? year;
  final String? manufacturer;
  final List<RecallInfo> recalls;
  final String? vehicleType;
  final String? engineInfo;
  final String? fuelType;
  final String? transmission;

  VehicleInfo({
    this.vin,
    this.make,
    this.model,
    this.year,
    this.manufacturer,
    this.recalls = const [],
    this.vehicleType,
    this.engineInfo,
    this.fuelType,
    this.transmission,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    List<RecallInfo> recallsList = [];
    if (json['recalls'] != null) {
      recallsList = (json['recalls'] as List)
          .map((r) => RecallInfo.fromJson(r))
          .toList();
    }

    return VehicleInfo(
      vin: json['vin']?.toString(),
      make: json['make']?.toString() ?? json['Make']?.toString(),
      model: json['model']?.toString() ?? json['Model']?.toString(),
      year: json['year']?.toString() ?? json['ModelYear']?.toString(),
      manufacturer: json['manufacturer']?.toString() ?? json['Manufacturer']?.toString(),
      recalls: recallsList,
      vehicleType: json['vehicle_type']?.toString() ?? json['VehicleType']?.toString(),
      engineInfo: json['engine_info']?.toString() ?? json['EngineModel']?.toString(),
      fuelType: json['fuel_type']?.toString() ?? json['FuelTypePrimary']?.toString(),
      transmission: json['transmission']?.toString() ?? json['TransmissionStyle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vin': vin,
      'make': make,
      'model': model,
      'year': year,
      'manufacturer': manufacturer,
      'recalls': recalls.map((r) => r.toJson()).toList(),
      'vehicle_type': vehicleType,
      'engine_info': engineInfo,
      'fuel_type': fuelType,
      'transmission': transmission,
    };
  }

  String get displayName {
    final parts = [year, make, model].where((p) => p != null && p.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : 'Vehicle';
  }

  bool get hasRecalls => recalls.isNotEmpty;
}

class RecallInfo {
  final String? campaignNumber;
  final String? summary;
  final String? consequence;
  final String? remedy;
  final String? reportDate;

  RecallInfo({
    this.campaignNumber,
    this.summary,
    this.consequence,
    this.remedy,
    this.reportDate,
  });

  factory RecallInfo.fromJson(Map<String, dynamic> json) {
    return RecallInfo(
      campaignNumber: json['campaign_number']?.toString() ?? json['NHTSACampaignNumber']?.toString(),
      summary: json['summary']?.toString() ?? json['Summary']?.toString(),
      consequence: json['consequence']?.toString() ?? json['Conequence']?.toString(),
      remedy: json['remedy']?.toString() ?? json['Remedy']?.toString(),
      reportDate: json['report_date']?.toString() ?? json['ReportReceivedDate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campaign_number': campaignNumber,
      'summary': summary,
      'consequence': consequence,
      'remedy': remedy,
      'report_date': reportDate,
    };
  }
}

class FairnessScore {
  final int score;
  final List<String> reasons;
  final String rating;

  FairnessScore({
    required this.score,
    this.reasons = const [],
    String? rating,
  }) : rating = rating ?? _calculateRating(score);

  static String _calculateRating(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }

  factory FairnessScore.fromJson(Map<String, dynamic> json) {
    return FairnessScore(
      score: json['fairness_score'] ?? json['score'] ?? 0,
      reasons: (json['reasons'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'reasons': reasons,
      'rating': rating,
    };
  }
}
