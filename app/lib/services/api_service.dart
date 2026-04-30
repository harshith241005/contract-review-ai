// API Service - Handles all backend communication

import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/contract.dart';
import '../models/sla_data.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late final Dio _dio;
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectionTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      headers: {
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }
  
  // Upload and analyze contract
  Future<ApiResponse<Contract>> analyzeContract(File file) async {
    try {
      String fileName = file.path.split(Platform.pathSeparator).last;
      
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });
      
      final response = await _dio.post(
        AppConfig.analyzeEndpoint,
        data: formData,
      );
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      final contract = Contract.fromJson(response.data);
      return ApiResponse.success(contract);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  // VIN Lookup
  Future<ApiResponse<VehicleInfo>> lookupVin(String vin) async {
    try {
      final response = await _dio.get(
        '${AppConfig.vinLookupEndpoint}/$vin',
      );
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      final vehicleInfo = VehicleInfo.fromJson(response.data);
      return ApiResponse.success(vehicleInfo);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  // Get negotiation points
  Future<ApiResponse<List<String>>> getNegotiationPoints(
    SlaData sla,
    Map<String, dynamic>? fairness,
  ) async {
    try {
      final response = await _dio.post(
        AppConfig.negotiationEndpoint,
        data: {
          'sla': sla.toJson(),
          'fairness': fairness,
        },
      );
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      final points = (response.data['points'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];
      return ApiResponse.success(points);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  // Get price estimate
  Future<ApiResponse<Map<String, dynamic>>> getPriceEstimate({
    required String make,
    required String model,
    required String year,
    String? zipCode,
  }) async {
    try {
      final response = await _dio.get(
        AppConfig.priceEstimateEndpoint,
        queryParameters: {
          'make': make,
          'model': model,
          'year': year,
          if (zipCode != null) 'zip': zipCode,
        },
      );
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  // Get all contracts
  Future<ApiResponse<List<Contract>>> getContracts() async {
    try {
      final response = await _dio.get('/contracts');
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      final contracts = (response.data['contracts'] as List<dynamic>?)
          ?.map((e) => Contract.fromJson(e))
          .toList() ?? [];
      return ApiResponse.success(contracts);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  // Get single contract by ID
  Future<ApiResponse<Contract>> getContract(int id) async {
    try {
      final response = await _dio.get('/contracts/$id');
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      final contract = Contract.fromJson(response.data);
      return ApiResponse.success(contract);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  // Delete contract
  Future<ApiResponse<bool>> deleteContract(int id) async {
    try {
      final response = await _dio.delete('/contracts/$id');
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      return ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  // Compare contracts
  Future<ApiResponse<Map<String, dynamic>>> compareContracts(List<int> ids) async {
    try {
      final idsString = ids.join(',');
      final response = await _dio.get('/compare', queryParameters: {'ids': idsString});
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  // Get VIN recalls
  Future<ApiResponse<Map<String, dynamic>>> getVinRecalls(String vin) async {
    try {
      final response = await _dio.get('/vin/$vin/recalls');
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  // Validate VIN
  Future<ApiResponse<Map<String, dynamic>>> validateVin(String vin) async {
    try {
      final response = await _dio.get('/vin/$vin/validate');
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  // Generate negotiation email
  Future<ApiResponse<String>> generateNegotiationEmail({
    required Map<String, dynamic> sla,
    required List<String> points,
    String customerName = "[Your Name]",
  }) async {
    try {
      final response = await _dio.post('/negotiate/email', data: {
        'sla': sla,
        'points': points,
        'customer_name': customerName,
      });
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      return ApiResponse.success(response.data['email']);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  // Get dealer questions
  Future<ApiResponse<List<String>>> getDealerQuestions() async {
    try {
      final response = await _dio.get('/negotiate/questions');
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      final questions = (response.data['questions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];
      return ApiResponse.success(questions);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  // Analyze contract using LLM
  Future<ApiResponse<Contract>> analyzeContractWithLlm(File file) async {
    try {
      String fileName = file.path.split(Platform.pathSeparator).last;
      
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });
      
      final response = await _dio.post(
        '/analyze-llm',
        data: formData,
      );
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      final contract = Contract.fromJson(response.data);
      return ApiResponse.success(contract);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  // Chat with assistant
  Future<ApiResponse<String>> chatWithAssistant({
    required String message,
    required Map<String, dynamic> sla,
  }) async {
    try {
      final response = await _dio.post('/chat', data: {
        'message': message,
        'sla': sla,
      });
      
      if (response.data['error'] != null) {
        return ApiResponse.error(response.data['error']);
      }
      
      return ApiResponse.success(response.data['response']);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }
  
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.receiveTimeout:
        return 'Server is taking too long to respond. Please try again.';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode}';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Make sure the backend is running.';
      default:
        return 'Network error: ${e.message}';
    }
  }
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  
  ApiResponse._({this.data, this.error, required this.isSuccess});
  
  factory ApiResponse.success(T data) {
    return ApiResponse._(data: data, isSuccess: true);
  }
  
  factory ApiResponse.error(String message) {
    return ApiResponse._(error: message, isSuccess: false);
  }
}
