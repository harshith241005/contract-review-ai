// App configuration and constants

class AppConfig {
  // API Base URL - Update this when deploying
  static const String apiBaseUrl = 'http://localhost:8001';
  
  // API Endpoints
  static const String analyzeEndpoint = '/analyze';
  static const String analyzeLlmEndpoint = '/analyze-llm';
  static const String vinLookupEndpoint = '/vin';
  static const String negotiationEndpoint = '/negotiate';
  static const String priceEstimateEndpoint = '/price-estimate';
  static const String contractsEndpoint = '/contracts';
  static const String compareEndpoint = '/compare';
  static const String samplesEndpoint = '/samples';
  
  // App Info
  static const String appName = 'Car Loan Assistant';
  static const String appVersion = '1.0.0';
  
  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 60000; // 60 seconds
  
  // File Upload
  static const int maxFileSizeMB = 10;
  static const List<String> allowedFileTypes = ['pdf', 'docx', 'jpg', 'jpeg', 'png'];
}
