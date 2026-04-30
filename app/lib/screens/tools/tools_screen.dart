import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/feature_card.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Car Tools',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0.5,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Analysis Tools'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                FeatureCard(
                  title: 'VIN Lookup',
                  description: 'Check vehicle history',
                  icon: FontAwesomeIcons.barcode,
                  color: AppTheme.infoColor,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.vinLookup),
                ),
                FeatureCard(
                  title: 'Price Estimate',
                  description: 'Market value',
                  icon: FontAwesomeIcons.dollarSign,
                  color: AppTheme.accentColor,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.priceEstimation),
                ),
                FeatureCard(
                  title: 'Comparison',
                  description: 'Compare offers',
                  icon: FontAwesomeIcons.scaleBalanced,
                  color: AppTheme.warningColor,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.comparison),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
