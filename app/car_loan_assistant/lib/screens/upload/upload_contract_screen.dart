// Upload Contract Screen

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/contract_provider.dart';

class UploadContractScreen extends StatefulWidget {
  const UploadContractScreen({super.key});

  @override
  State<UploadContractScreen> createState() => _UploadContractScreenState();
}

class _UploadContractScreenState extends State<UploadContractScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  String? _fileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Contract'),
      ),
      body: Consumer<ContractProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading || _isUploading) {
            return _buildLoadingView();
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Icon(
                  Icons.description_outlined,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Upload Your Contract',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ll analyze your car lease or loan contract and extract key terms',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Upload Area
                _buildUploadArea(),
                
                const SizedBox(height: 24),
                
                // Selected File Preview
                if (_selectedFile != null) ...[
                  _buildSelectedFileCard(),
                  const SizedBox(height: 24),
                ],
                
                // Upload Options
                _buildUploadOptions(),
                
                const SizedBox(height: 32),
                
                // Analyze Button
                if (_selectedFile != null)
                  ElevatedButton(
                    onPressed: _analyzeContract,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Analyze with AI',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                
                // Error Message
                if (provider.error != null) ...[
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
                            provider.error!,
                            style: const TextStyle(color: AppTheme.errorColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Supported Formats
                _buildSupportedFormats(),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SpinKitDoubleBounce(
            color: AppTheme.primaryColor,
            size: 60,
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing your contract...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          _buildAnalyzingSteps(),
        ],
      ),
    );
  }
  
  Widget _buildAnalyzingSteps() {
    return Column(
      children: [
        _buildStepItem('Extracting text from document', true),
        _buildStepItem('Processing with AI', true),
        _buildStepItem('Identifying key terms', true),
        _buildStepItem('Calculating fairness score', true),
      ],
    );
  }
  
  Widget _buildStepItem(String text, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.circle_outlined, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isActive ? AppTheme.primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUploadArea() {
    return InkWell(
      onTap: _pickPdfFile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.primaryColor.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap to upload PDF or DOCX',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'or choose an option below',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSelectedFileCard() {
    return Card(
      color: AppTheme.successColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.successColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.insert_drive_file,
              color: AppTheme.successColor,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fileName ?? 'Selected File',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to analyze',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _selectedFile = null;
                  _fileName = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUploadOptions() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionButton(
            icon: Icons.picture_as_pdf,
            label: 'PDF',
            onTap: _pickPdfFile,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionButton(
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: _takePhoto,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionButton(
            icon: Icons.photo_library,
            label: 'Gallery',
            onTap: _pickFromGallery,
          ),
        ),
      ],
    );
  }
  
  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
  
  Widget _buildSupportedFormats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Supported Formats',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFormatChip('PDF'),
              _buildFormatChip('DOCX'),
              _buildFormatChip('JPG'),
              _buildFormatChip('PNG'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFormatChip(String format) {
    return Chip(
      label: Text(
        format,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.white,
      padding: EdgeInsets.zero,
    );
  }
  
  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );
      
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }
  
  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      
      if (photo != null) {
        setState(() {
          _selectedFile = File(photo.path);
          _fileName = photo.name;
        });
      }
    } catch (e) {
      _showError('Failed to take photo: $e');
    }
  }
  
  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _fileName = image.name;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }
  
  Future<void> _analyzeContract() async {
    if (_selectedFile == null) return;
    
    setState(() => _isUploading = true);
    
    final provider = context.read<ContractProvider>();
    final success = await provider.analyzeContract(_selectedFile!);
    
    setState(() => _isUploading = false);
    
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.review);
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}
