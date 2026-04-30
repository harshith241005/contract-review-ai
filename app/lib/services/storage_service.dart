// Storage Service - Local data persistence

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contract.dart';

class StorageService {
  static const String _contractHistoryKey = 'contract_history';
  static const String _savedVinsKey = 'saved_vins';
  
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Contract History
  static Future<void> saveContractToHistory(Contract contract) async {
    final history = await getContractHistory();
    history.insert(0, contract); // Add to beginning
    
    // Keep only last 50 contracts
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    
    final jsonList = history.map((c) => c.toJson()).toList();
    await _prefs?.setString(_contractHistoryKey, json.encode(jsonList));
  }
  
  static Future<List<Contract>> getContractHistory() async {
    final jsonString = _prefs?.getString(_contractHistoryKey);
    if (jsonString == null) return [];
    
    try {
      final jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList.map((j) => Contract.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }
  
  static Future<void> clearContractHistory() async {
    await _prefs?.remove(_contractHistoryKey);
  }
  
  // Saved VINs
  static Future<void> saveVin(String vin, VehicleInfo info) async {
    final savedVins = await getSavedVins();
    savedVins[vin] = info.toJson();
    await _prefs?.setString(_savedVinsKey, json.encode(savedVins));
  }
  
  static Future<Map<String, dynamic>> getSavedVins() async {
    final jsonString = _prefs?.getString(_savedVinsKey);
    if (jsonString == null) return {};
    
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
  
  // User Preferences
  static Future<void> setApiUrl(String url) async {
    await _prefs?.setString('api_url', url);
  }
  
  static String? getApiUrl() {
    return _prefs?.getString('api_url');
  }
  
  static Future<void> setDarkMode(bool enabled) async {
    await _prefs?.setBool('dark_mode', enabled);
  }
  
  static bool getDarkMode() {
    return _prefs?.getBool('dark_mode') ?? false;
  }
}
