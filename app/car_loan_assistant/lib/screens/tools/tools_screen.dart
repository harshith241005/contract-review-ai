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
      appBar: AppBar(
        title: const Text('Car Tools'),
        elevation: 0,
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
            const SizedBox(height: 24),
            
            _buildSectionHeader('Information'),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              'Interest Rate Guide',
              'Learn about current market rates',
              Icons.trending_up,
              Colors.orange,
            ),
            _buildInfoCard(
              context,
              'Negotiation Checklist',
              'Crucial things to check at the dealer',
              Icons.fact_check_outlined,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
