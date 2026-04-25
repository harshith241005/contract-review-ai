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
    
    // Initialize storage before other operations
    print('Initializing StorageService...');
    await StorageService.init();
    print('StorageService initialized');
    
    // Global error handler to show on screen
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CRITICAL RENDERING ERROR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 10),
                  Text(details.exception.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(details.stack.toString(), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      );
    };
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
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

