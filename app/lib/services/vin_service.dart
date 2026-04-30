// VIN Service - Direct NHTSA API calls for VIN lookup
// Also supports backend API fallback

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/contract.dart';

class VinService {
  static const String _nhtsaBaseUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles';
  
  // Try backend first, fallback to direct NHTSA API
  static Future<VehicleInfo?> lookupVin(String vin, {bool useBackend = true}) async {
    if (useBackend) {
      try {
        final backendResult = await _lookupViaBackend(vin);
        if (backendResult != null) return backendResult;
      } catch (e) {
        // Fallback to direct NHTSA
      }
    }
    return getFullVehicleReport(vin);
  }
  
  // Lookup via backend API
  static Future<VehicleInfo?> _lookupViaBackend(String vin) async {
    try {
      final url = '${AppConfig.apiBaseUrl}${AppConfig.vinLookupEndpoint}/$vin';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) return null;
        
        List<RecallInfo> recalls = [];
        if (data['recalls'] != null) {
          recalls = (data['recalls'] as List<dynamic>)
              .map((r) => RecallInfo.fromJson(r))
              .toList();
        }
        
        return VehicleInfo(
          vin: data['vin'],
          make: data['make'],
          model: data['model'],
          year: data['year'],
          manufacturer: data['manufacturer'],
          vehicleType: data['vehicle_type'],
          engineInfo: data['engine_info'],
          fuelType: data['fuel_type'],
          transmission: data['transmission'],
          recalls: recalls,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Decode VIN to get vehicle details
  static Future<VehicleInfo?> decodeVin(String vin) async {
    try {
      final url = '$_nhtsaBaseUrl/DecodeVin/$vin?format=json';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['Results'] as List<dynamic>?;
        
        if (results == null || results.isEmpty) {
          return null;
        }
        
        // Parse NHTSA response into VehicleInfo
        final vehicleData = <String, String>{};
        for (var item in results) {
          final variable = item['Variable'] as String?;
          final value = item['Value'] as String?;
          if (variable != null && value != null && value.isNotEmpty) {
            vehicleData[variable] = value;
          }
        }
        
        return VehicleInfo(
          vin: vin,
          make: vehicleData['Make'],
          model: vehicleData['Model'],
          year: vehicleData['Model Year'],
          manufacturer: vehicleData['Manufacturer Name'],
          vehicleType: vehicleData['Vehicle Type'],
          engineInfo: vehicleData['Engine Model'] ?? 
              '${vehicleData['Engine Number of Cylinders'] ?? ''} cylinder ${vehicleData['Displacement (L)'] ?? ''} L',
          fuelType: vehicleData['Fuel Type - Primary'],
          transmission: vehicleData['Transmission Style'],
        );
      }
      return null;
    } catch (e) {
      print('Error decoding VIN: $e');
      return null;
    }
  }
  
  // Get recalls for a VIN
  static Future<List<RecallInfo>> getRecalls(String vin) async {
    try {
      // First get the make, model, year from VIN
      final vehicle = await decodeVin(vin);
      if (vehicle == null) return [];
      
      final url = 'https://api.nhtsa.gov/recalls/recallsByVehicle?make=${vehicle.make}&model=${vehicle.model}&modelYear=${vehicle.year}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>?;
        
        if (results == null || results.isEmpty) {
          return [];
        }
        
        return results.map((r) => RecallInfo(
          campaignNumber: r['NHTSACampaignNumber']?.toString(),
          summary: r['Summary']?.toString(),
          consequence: r['Consequence']?.toString(),
          remedy: r['Remedy']?.toString(),
          reportDate: r['ReportReceivedDate']?.toString(),
        )).toList();
      }
      return [];
    } catch (e) {
      print('Error getting recalls: $e');
      return [];
    }
  }
  
  // Get full vehicle report (VIN decode + recalls)
  static Future<VehicleInfo?> getFullVehicleReport(String vin) async {
    try {
      final vehicle = await decodeVin(vin);
      if (vehicle == null) return null;
      
      final recalls = await getRecalls(vin);
      
      return VehicleInfo(
        vin: vehicle.vin,
        make: vehicle.make,
        model: vehicle.model,
        year: vehicle.year,
        manufacturer: vehicle.manufacturer,
        vehicleType: vehicle.vehicleType,
        engineInfo: vehicle.engineInfo,
        fuelType: vehicle.fuelType,
        transmission: vehicle.transmission,
        recalls: recalls,
      );
    } catch (e) {
      print('Error getting full vehicle report: $e');
      return null;
    }
  }
  
  // Validate VIN format
  static bool isValidVin(String vin) {
    // VIN must be exactly 17 characters
    if (vin.length != 17) return false;
    
    // VIN cannot contain I, O, Q
    if (vin.contains(RegExp(r'[IOQ]', caseSensitive: false))) {
      return false;
    }
    
    // VIN must be alphanumeric
    return RegExp(r'^[A-HJ-NPR-Z0-9]{17}$', caseSensitive: false).hasMatch(vin);
  }
}
