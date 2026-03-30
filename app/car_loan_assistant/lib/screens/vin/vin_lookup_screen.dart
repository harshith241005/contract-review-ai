// VIN Lookup Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config/theme.dart';
import '../../models/contract.dart';
import '../../providers/contract_provider.dart';
import '../../services/vin_service.dart';
import '../../services/storage_service.dart';

class VinLookupScreen extends StatefulWidget {
  const VinLookupScreen({super.key});

  @override
  State<VinLookupScreen> createState() => _VinLookupScreenState();
}

class _VinLookupScreenState extends State<VinLookupScreen> {
  final TextEditingController _vinController = TextEditingController();
  bool _isLoading = false;
  VehicleInfo? _vehicleInfo;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final contract = context.read<ContractProvider>().currentContract;
      final vin = contract?.vehicleInfo?.vin?.trim();
      if (vin != null && vin.isNotEmpty) {
        setState(() {
          _vinController.text = vin;
          _vehicleInfo = contract?.vehicleInfo;
        });
      }
    });
  }

  @override
  void dispose() {
    _vinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VIN Lookup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Icon(
              FontAwesomeIcons.barcode,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Vehicle Identification Number',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a 17-character VIN to get vehicle details and recall information',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // VIN Input
            TextField(
              controller: _vinController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 17,
              decoration: InputDecoration(
                labelText: 'VIN Number',
                hintText: 'e.g., 1HGBH41JXMN109186',
                prefixIcon: const Icon(FontAwesomeIcons.car),
                suffixIcon: _vinController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _vinController.clear();
                          setState(() {
                            _vehicleInfo = null;
                            _error = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // VIN Validation Hint
            if (_vinController.text.isNotEmpty && _vinController.text.length < 17)
              Text(
                '${17 - _vinController.text.length} more characters needed',
                style: const TextStyle(color: AppTheme.warningColor),
                textAlign: TextAlign.center,
              ),
            
            // Search Button
            ElevatedButton(
              onPressed: _isLoading ? null : _lookupVin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Look Up Vehicle', style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 8),

            Consumer<ContractProvider>(
              builder: (context, provider, child) {
                final contractVin = provider.currentContract?.vehicleInfo?.vin;
                if (contractVin == null || contractVin.isEmpty) {
                  return const SizedBox.shrink();
                }
                return OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _vinController.text = contractVin;
                      _error = null;
                    });
                    _lookupVin();
                  },
                  icon: const Icon(Icons.assignment_turned_in),
                  label: const Text('Use Current Contract VIN'),
                );
              },
            ),
            
            // Error Message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Loading State
            if (_isLoading) ...[
              const SizedBox(height: 32),
              const Center(
                child: SpinKitDoubleBounce(
                  color: AppTheme.primaryColor,
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fetching vehicle information...',
                textAlign: TextAlign.center,
              ),
            ],
            
            // Vehicle Info Results
            if (_vehicleInfo != null) ...[
              const SizedBox(height: 32),
              _buildVehicleInfoCard(),
              const SizedBox(height: 16),
              _buildSpecificationsCard(),
              if (_vehicleInfo!.hasRecalls) ...[
                const SizedBox(height: 16),
                _buildRecallsCard(),
              ],
            ],
            
            // Example VINs
            const SizedBox(height: 32),
            _buildExampleVins(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVehicleInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.car,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vehicleInfo!.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _vehicleInfo!.manufacturer ?? 'Unknown Manufacturer',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: _saveVin,
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('VIN', _vehicleInfo!.vin ?? 'N/A'),
            _buildInfoRow('Year', _vehicleInfo!.year ?? 'N/A'),
            _buildInfoRow('Make', _vehicleInfo!.make ?? 'N/A'),
            _buildInfoRow('Model', _vehicleInfo!.model ?? 'N/A'),
            _buildInfoRow('Type', _vehicleInfo!.vehicleType ?? 'N/A'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpecificationsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: AppTheme.infoColor),
                SizedBox(width: 8),
                Text(
                  'Specifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Engine', _vehicleInfo!.engineInfo ?? 'N/A'),
            _buildInfoRow('Fuel Type', _vehicleInfo!.fuelType ?? 'N/A'),
            _buildInfoRow('Transmission', _vehicleInfo!.transmission ?? 'N/A'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecallsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.warningColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text(
                  'Active Recalls (${_vehicleInfo!.recalls.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...(_vehicleInfo!.recalls.take(3).map((recall) => _buildRecallItem(recall))),
            if (_vehicleInfo!.recalls.length > 3)
              TextButton(
                onPressed: () {
                  // TODO: Show all recalls in a dialog or new screen
                },
                child: Text('View all ${_vehicleInfo!.recalls.length} recalls'),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecallItem(RecallInfo recall) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recall.campaignNumber != null)
            Text(
              'Campaign: ${recall.campaignNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            recall.summary ?? 'No description available',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExampleVins() {
    final examples = [
      ('Honda Accord', '1HGBH41JXMN109186'),
      ('Toyota Camry', '4T1B11HK5JU123456'),
      ('Ford F-150', '1FTEW1EP0JKE12345'),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Example VINs to try:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...examples.map((e) => InkWell(
          onTap: () {
            _vinController.text = e.$2;
            setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.car_rental, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${e.$1}: ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  e.$2,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
  
  Future<void> _lookupVin() async {
    final vin = _vinController.text.trim().toUpperCase();
    
    if (vin.isEmpty) {
      setState(() => _error = 'Please enter a VIN');
      return;
    }
    
    if (!VinService.isValidVin(vin)) {
      setState(() => _error = 'Invalid VIN format. VIN must be 17 characters (no I, O, or Q)');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
      _vehicleInfo = null;
    });
    
    try {
      // Try backend first, then fallback to direct NHTSA API
      final vehicleInfo = await VinService.lookupVin(vin, useBackend: true);
      
      setState(() {
        _isLoading = false;
        if (vehicleInfo != null) {
          _vehicleInfo = vehicleInfo;
        } else {
          _error = 'Could not find vehicle information for this VIN';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error looking up VIN: $e';
      });
    }
  }
  
  Future<void> _saveVin() async {
    if (_vehicleInfo == null) return;
    
    await StorageService.saveVin(_vehicleInfo!.vin!, _vehicleInfo!);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VIN saved successfully')),
      );
    }
  }
}
