// Car Loan Assistant - Main Entry Point

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/contract_provider.dart';
import 'providers/negotiation_provider.dart';
import 'services/storage_service.dart';

void main() async {
  print('--- MINIMAL APP STARTING ---');
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('WidgetsFlutterBinding initialized');
  } catch (e, stack) {
    print('CRITICAL ERROR DURING INIT: $e');
    print(stack.toString());
  }
  
  runApp(const CarLoanAssistantApp());
  print('runApp called');
}

class CarLoanAssistantApp extends StatelessWidget {
  const CarLoanAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContractProvider()),
        ChangeNotifierProvider(create: (_) => NegotiationProvider()),
      ],
      child: MaterialApp(
        title: 'Car Loan Assistant',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.home,
        routes: AppRoutes.routes,
        builder: (context, child) {
          print('MaterialApp builder called. Child null? ${child == null}');
          if (child == null) {
            print('MaterialApp builder: child is NULL');
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child,
          );
        },
      ),
    );
  }
}

