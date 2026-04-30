// Contract Provider - State management for contracts

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/contract.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ContractProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Current contract being analyzed
  Contract? _currentContract;
  Contract? get currentContract => _currentContract;
  
  // List of contracts for comparison
  List<Contract> _comparisonContracts = [];
  List<Contract> get comparisonContracts => _comparisonContracts;
  
  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Error state
  String? _error;
  String? get error => _error;
  
  // Analyze a contract file
  Future<bool> analyzeContract(File file) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.analyzeContract(file);
      
      if (response.isSuccess && response.data != null) {
        _currentContract = response.data;
        // Save to history
        await StorageService.saveContractToHistory(_currentContract!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to analyze contract';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error analyzing contract: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Set current contract (from history or comparison)
  void setCurrentContract(Contract contract) {
    _currentContract = contract;
    notifyListeners();
  }
  
  // Add contract to comparison list
  void addToComparison(Contract contract) {
    if (!_comparisonContracts.any((c) => c.id == contract.id)) {
      _comparisonContracts.add(contract);
      notifyListeners();
    }
  }
  
  // Remove from comparison
  void removeFromComparison(Contract contract) {
    _comparisonContracts.removeWhere((c) => c.id == contract.id);
    notifyListeners();
  }
  
  // Clear comparison list
  void clearComparison() {
    _comparisonContracts.clear();
    notifyListeners();
  }
  
  // Load contract history
  Future<List<Contract>> loadHistory() async {
    try {
      final localHistory = await StorageService.getContractHistory();
      final backendResponse = await _apiService.getContracts();

      final merged = <String, Contract>{};

      for (final contract in localHistory) {
        final key = '${contract.id}-${contract.fileName}-${contract.createdAt.toIso8601String()}';
        merged[key] = contract;
      }

      if (backendResponse.isSuccess && backendResponse.data != null) {
        for (final contract in backendResponse.data!) {
          final key = '${contract.id}-${contract.fileName}-${contract.createdAt.toIso8601String()}';
          merged.putIfAbsent(key, () => contract);
        }
      }

      final allContracts = merged.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allContracts;
    } catch (_) {
      return StorageService.getContractHistory();
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Get fairness score color
  Color getFairnessColor(int? score) {
    if (score == null) return Colors.grey;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
  
  // Get fairness rating text
  String getFairnessRating(int? score) {
    if (score == null) return 'Unknown';
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }
}
