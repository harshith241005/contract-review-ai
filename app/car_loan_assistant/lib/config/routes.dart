import 'package:flutter/material.dart';
import '../screens/upload/upload_contract_screen.dart';
import '../screens/review/contract_review_screen.dart';
import '../screens/negotiation/negotiation_screen.dart';
import '../screens/vin/vin_lookup_screen.dart';
import '../screens/comparison/comparison_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/price/price_estimation_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/main_screen.dart';
import '../screens/tools/tools_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String upload = '/upload';
  static const String review = '/review';
  static const String negotiation = '/negotiation';
  static const String vinLookup = '/vin-lookup';
  static const String comparison = '/comparison';
  static const String history = '/history';
  static const String priceEstimation = '/price-estimation';
  static const String settings = '/settings';
  static const String tools = '/tools';
  
  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const MainScreen(),
    upload: (context) => const UploadContractScreen(),
    review: (context) => const ContractReviewScreen(),
    negotiation: (context) => const NegotiationScreen(),
    vinLookup: (context) => const VinLookupScreen(),
    comparison: (context) => const ComparisonScreen(),
    history: (context) => const HistoryScreen(),
    priceEstimation: (context) => const PriceEstimationScreen(),
    settings: (context) => const SettingsScreen(),
    tools: (context) => const ToolsScreen(),
  };
}
