import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/contract_provider.dart';
import '../../services/api_service.dart';

class PriceEstimationScreen extends StatefulWidget {
  const PriceEstimationScreen({super.key});

  @override
  State<PriceEstimationScreen> createState() => _PriceEstimationScreenState();
}

class _PriceEstimationScreenState extends State<PriceEstimationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _zipController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingModels = false;
  Map<String, dynamic>? _priceData;
  String? _error;
  List<String> _availableModels = [];
  
  // Comprehensive list of car makes (Global + Indian)
  final List<String> _popularMakes = [
    // Japanese
    'Toyota', 'Honda', 'Nissan', 'Mazda', 'Subaru', 'Mitsubishi', 'Suzuki', 'Daihatsu',
    // Korean
    'Hyundai', 'Kia', 'Genesis',
    // American
    'Ford', 'Chevrolet', 'GMC', 'RAM', 'Dodge', 'Jeep', 'Tesla',
    // European
    'BMW', 'Mercedes-Benz', 'Audi', 'Volkswagen', 'Skoda', 'Volvo', 'Porsche', 'Jaguar', 'Land Rover',
    // Luxury
    'Lexus', 'Acura', 'Infiniti', 'Genesis', 'Lincoln',
    // Indian Brands
    'Tata', 'Maruti Suzuki', 'Mahindra', 'Bajaj',
    // Chinese
    'BYD', 'Geely',
    // British
    'MG', 'MINI',
    // Other
    'Renault', 'Peugeot', 'Citroën', 'Fiat', 'Hyundai', 'Force',
  ];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final contract = context.read<ContractProvider>().currentContract;
      final vehicle = contract?.vehicleInfo;
      if (vehicle != null) {
        if ((vehicle.make ?? '').isNotEmpty) _makeController.text = vehicle.make!;
        if ((vehicle.model ?? '').isNotEmpty) _modelController.text = vehicle.model!;
        if ((vehicle.year ?? '').isNotEmpty) _yearController.text = vehicle.year!;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _zipController.dispose();
    super.dispose();
  }
  
  Future<void> _getPriceEstimate() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
      _priceData = null;
    });
    
    try {
      final apiService = ApiService();
      final result = await apiService.getPriceEstimate(
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: _yearController.text.trim(),
        zipCode: _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
      );
      
      setState(() {
        if (result.isSuccess && result.data != null) {
          _priceData = result.data;
        } else {
          _error = result.error ?? 'Failed to get price estimate';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Estimation'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.successColor,
                    AppTheme.successColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.dollarSign,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get Price Estimate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Estimate market value based on make, model & year',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Input Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Make Field with Autocomplete
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _popularMakes.where((make) =>
                          make.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      _makeController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      // Sync controllers
                      controller.text = _makeController.text;
                      controller.addListener(() {
                        _makeController.text = controller.text;
                      });
                      
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Make',
                          hintText: 'e.g., Toyota, Honda, Ford',
                          prefixIcon: const Icon(Icons.directions_car),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the vehicle make';
                          }
                          return null;
                        },
                        onEditingComplete: onEditingComplete,
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Model Field
                  TextFormField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      labelText: 'Model',
                      hintText: 'e.g., Camry, Accord, F-150',
                      prefixIcon: const Icon(Icons.local_offer),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the vehicle model';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Year Field
                  TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      hintText: 'e.g., 2023',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the vehicle year';
                      }
                      final year = int.tryParse(value);
                      if (year == null || year < 1980 || year > 2026) {
                        return 'Please enter a valid year (1980-2026)';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ZIP Code Field (Optional)
                  TextFormField(
                    controller: _zipController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ZIP Code (Optional)',
                      hintText: 'e.g., 90210',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getPriceEstimate,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const FaIcon(FontAwesomeIcons.magnifyingGlassDollar),
                      label: Text(_isLoading ? 'Estimating...' : 'Get Price Estimate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Error Display
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Price Results
            if (_priceData != null) ...[
              _buildPriceResultCard(),
              const SizedBox(height: 16),
              _buildPriceRangeCard(),
              const SizedBox(height: 16),
              _buildDisclaimerCard(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceResultCard() {
    final estimatedPrice = _priceData!['estimated_price'] ?? 0;
    final category = _priceData!['category'] ?? 'unknown';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Estimated Value',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_formatPrice(estimatedPrice)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_priceData!['year']} ${_priceData!['make']} ${_priceData!['model']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceRangeCard() {
    final priceRange = _priceData!['price_range'] as Map<String, dynamic>?;
    if (priceRange == null) return const SizedBox();
    
    final lowPrice = priceRange['low'] ?? 0;
    final highPrice = priceRange['high'] ?? 0;
    final estimatedPrice = _priceData!['estimated_price'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FaIcon(FontAwesomeIcons.chartLine, size: 18, color: AppTheme.infoColor),
              SizedBox(width: 8),
              Text(
                'Price Range',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceBox('Low', lowPrice, AppTheme.warningColor),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              _buildPriceBox('Estimated', estimatedPrice, AppTheme.successColor),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              _buildPriceBox('High', highPrice, AppTheme.infoColor),
            ],
          ),
          const SizedBox(height: 16),
          // Price bar visualization
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.7,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.warningColor, AppTheme.successColor, AppTheme.infoColor],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceBox(String label, int price, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${_formatPrice(price)}',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _priceData!['disclaimer'] ?? 
              'Prices are estimates based on vehicle category and age. Actual prices vary by condition, mileage, and location.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
