// Home Screen - Main dashboard

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/recent_contracts_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('HomeScreen is building!');
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Car Loan Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryLight,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      const Positioned(
                        right: 20,
                        bottom: 60,
                        child: Icon(
                          FontAwesomeIcons.car,
                          size: 80,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: const [
                SizedBox(width: 8),
              ],
            ),
            
            // Welcome Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back! 👋',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload a contract to get started with AI-powered analysis',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildQuickUploadCard(context),
              ),
            ),
            
            // Features Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildFeaturesGrid(context),
                  ],
                ),
              ),
            ),
            
            // Recent Contracts
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Contracts',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const RecentContractsWidget(),
                  ],
                ),
              ),
            ),
            
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.upload),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text(
          'Analyze Contract',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
  
  Widget _buildQuickUploadCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.upload),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppTheme.accentColor, AppTheme.accentLight],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.upload_file,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Contract',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF or Image • AI-Powered Analysis',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeaturesGrid(BuildContext context) {
    return GridView.count(
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
          title: 'Negotiation',
          description: 'AI assistant',
          icon: FontAwesomeIcons.comments,
          color: AppTheme.successColor,
          onTap: () => Navigator.pushNamed(context, AppRoutes.negotiation),
        ),
        FeatureCard(
          title: 'Compare',
          description: 'Multiple offers',
          icon: FontAwesomeIcons.scaleBalanced,
          color: AppTheme.warningColor,
          onTap: () => Navigator.pushNamed(context, AppRoutes.comparison),
        ),
        FeatureCard(
          title: 'History',
          description: 'Past contracts',
          icon: FontAwesomeIcons.clockRotateLeft,
          color: AppTheme.primaryLight,
          onTap: () => Navigator.pushNamed(context, AppRoutes.history),
        ),
        FeatureCard(
          title: 'Price Estimate',
          description: 'Market value',
          icon: FontAwesomeIcons.dollarSign,
          color: AppTheme.accentColor,
          onTap: () => Navigator.pushNamed(context, AppRoutes.priceEstimation),
        ),
      ],
    );
  }
}
