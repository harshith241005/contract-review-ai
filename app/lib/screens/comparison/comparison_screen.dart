// Comparison Screen - Compare multiple contracts

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/contract_provider.dart';
import '../../models/contract.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ContractProvider>();
      final current = provider.currentContract;
      if (current != null && !provider.comparisonContracts.any((c) => c.id == current.id)) {
        provider.addToComparison(current);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Contracts'),
        actions: [
          Consumer<ContractProvider>(
            builder: (context, provider, child) {
              if (provider.comparisonContracts.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () => provider.clearComparison(),
                  tooltip: 'Clear All',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<ContractProvider>(
        builder: (context, provider, child) {
          final contracts = provider.comparisonContracts;
          
          if (contracts.isEmpty) {
            return _buildEmptyState(context);
          }
          
          if (contracts.length == 1) {
            return _buildSingleContractView(context, contracts.first, provider);
          }
          
          return _buildComparisonView(context, contracts, provider);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.upload),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Contract', style: TextStyle(color: Colors.white)),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.scaleBalanced,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Contracts to Compare',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload and analyze contracts, then add them here to compare side by side',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.upload),
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text('Upload Contract', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSingleContractView(BuildContext context, Contract contract, ContractProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.infoColor),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.infoColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add at least one more contract to compare',
                    style: TextStyle(color: AppTheme.infoColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildContractCard(context, contract, provider, true),
        ),
      ],
    );
  }
  
  Widget _buildComparisonView(BuildContext context, List<Contract> contracts, ContractProvider provider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Contracts side by side
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              itemCount: contracts.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 280,
                  child: _buildContractCard(context, contracts[index], provider, false),
                );
              },
            ),
          ),
          
          // Comparison Table
          _buildComparisonTable(context, contracts),
          
          // Recommendation
          _buildRecommendation(context, contracts),
          
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }
  
  Widget _buildContractCard(BuildContext context, Contract contract, ContractProvider provider, bool isExpanded) {
    final fairnessScore = contract.slaData?.contractFairnessScore ?? 
        contract.fairnessScore?.score ?? 0;
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contract.fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => provider.removeFromComparison(contract),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            _buildScoreIndicator(fairnessScore),
            const SizedBox(height: 12),
            if (contract.slaData != null) ...[
              _buildTermRow('APR', '${contract.slaData!.interestRateApr ?? 'N/A'}%'),
              _buildTermRow('Monthly', '\$${contract.slaData!.monthlyPayment ?? 'N/A'}'),
              _buildTermRow('Term', '${contract.slaData!.leaseTermMonths ?? 'N/A'} months'),
              _buildTermRow('Down', '\$${contract.slaData!.downPayment ?? 'N/A'}'),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildScoreIndicator(int score) {
    final color = AppTheme.getFairnessColor(score);
    
    return Row(
      children: [
        Text(
          '$score',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const Text(
          '/100',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getRating(score),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTermRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  
  Widget _buildComparisonTable(BuildContext context, List<Contract> contracts) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Side-by-Side Comparison',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Term')),
                  ...contracts.map((c) => DataColumn(
                    label: Text(
                      c.fileName.length > 15 
                          ? '${c.fileName.substring(0, 12)}...'
                          : c.fileName,
                    ),
                  )),
                ],
                rows: [
                  _buildDataRow('Fairness', contracts.map((c) => 
                      '${c.slaData?.contractFairnessScore ?? c.fairnessScore?.score ?? "N/A"}').toList()),
                  _buildDataRow('APR', contracts.map((c) => 
                      '${c.slaData?.interestRateApr ?? "N/A"}%').toList()),
                  _buildDataRow('Monthly', contracts.map((c) => 
                      '\$${c.slaData?.monthlyPayment ?? "N/A"}').toList()),
                  _buildDataRow('Term', contracts.map((c) => 
                      '${c.slaData?.leaseTermMonths ?? "N/A"} mo').toList()),
                  _buildDataRow('Down', contracts.map((c) => 
                      '\$${c.slaData?.downPayment ?? "N/A"}').toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  DataRow _buildDataRow(String term, List<String> values) {
    return DataRow(
      cells: [
        DataCell(Text(term, style: const TextStyle(fontWeight: FontWeight.w500))),
        ...values.map((v) => DataCell(Text(v))),
      ],
    );
  }
  
  Widget _buildRecommendation(BuildContext context, List<Contract> contracts) {
    // Find best contract (highest fairness score)
    Contract? bestContract;
    int bestScore = 0;
    
    for (var contract in contracts) {
      final score = contract.slaData?.contractFairnessScore ?? 
          contract.fairnessScore?.score ?? 0;
      if (score > bestScore) {
        bestScore = score;
        bestContract = contract;
      }
    }
    
    if (bestContract == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: AppTheme.successColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.successColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.recommend, color: AppTheme.successColor),
                  SizedBox(width: 8),
                  Text(
                    'Recommendation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Based on the fairness scores, "${bestContract.fileName}" appears to offer the best terms with a score of $bestScore/100.',
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  final provider = context.read<ContractProvider>();
                  provider.setCurrentContract(bestContract!);
                  Navigator.pushNamed(context, AppRoutes.negotiation);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.successColor,
                  side: const BorderSide(color: AppTheme.successColor),
                ),
                child: const Text('Get Negotiation Tips'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getRating(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }
}
