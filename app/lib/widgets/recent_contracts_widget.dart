// Recent Contracts Widget

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/contract.dart';
import '../providers/contract_provider.dart';
import '../services/storage_service.dart';

class RecentContractsWidget extends StatefulWidget {
  const RecentContractsWidget({super.key});

  @override
  State<RecentContractsWidget> createState() => _RecentContractsWidgetState();
}

class _RecentContractsWidgetState extends State<RecentContractsWidget> {
  List<Contract> _recentContracts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentContracts();
  }

  Future<void> _loadRecentContracts() async {
    final contracts = await StorageService.getContractHistory();
    setState(() {
      _recentContracts = contracts.take(3).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentContracts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            const Text(
              'No contracts yet',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload your first contract to get started',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentContracts.map((contract) => _buildContractItem(contract)).toList(),
    );
  }

  Widget _buildContractItem(Contract contract) {
    final fairnessScore = contract.slaData?.contractFairnessScore ?? 
        contract.fairnessScore?.score ?? 0;
    final color = AppTheme.getFairnessColor(fairnessScore);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          context.read<ContractProvider>().setCurrentContract(contract);
          Navigator.pushNamed(context, AppRoutes.review);
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$fairnessScore',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        title: Text(
          contract.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(contract.createdAt),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
