// App configuration and constants

class AppConfig {
  // Default API Base URL for local desktop/web development.
  // Use Settings to override this when targeting Android emulator (10.0.2.2).
  static const String apiBaseUrl = 'http://localhost:8000';
  
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
  static const int connectionTimeout = 60000; // 60 seconds
  static const int receiveTimeout = 600000; // 10 minutes (Local LLMs can be very slow)
  
  // File Upload
  static const int maxFileSizeMB = 10;
  static const List<String> allowedFileTypes = ['pdf', 'docx', 'jpg', 'jpeg', 'png'];
}
