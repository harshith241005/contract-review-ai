import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  String _selectedCurrency = 'USD (\$)';
  String _selectedLanguage = 'English';
  final TextEditingController _apiUrlController = TextEditingController(text: AppConfig.apiBaseUrl);

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('User Profile'),
          _buildProfileCard(),
          const SizedBox(height: 24),
          
          _buildSectionHeader('App Preferences'),
          _buildSettingsCard([
            _buildSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: 'Enable dark theme for the app',
              value: _darkMode,
              onChanged: (val) => setState(() => _darkMode = val),
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.notifications_none_outlined,
              title: 'Notifications',
              subtitle: 'Receive alerts for contract analysis',
              value: _notificationsEnabled,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('Regional'),
          _buildSettingsCard([
            _buildDropdownTile(
              icon: Icons.monetization_on_outlined,
              title: 'Currency',
              value: _selectedCurrency,
              items: ['USD (\$)', 'EUR (€)', 'GBP (£)', 'CAD (\$)'],
              onChanged: (val) => setState(() => _selectedCurrency = val!),
            ),
            _buildDivider(),
            _buildDropdownTile(
              icon: Icons.language_outlined,
              title: 'Language',
              value: _selectedLanguage,
              items: ['English', 'Spanish', 'French', 'German'],
              onChanged: (val) => setState(() => _selectedLanguage = val!),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('Technical'),
          _buildSettingsCard([
            _buildTextFieldTile(
              icon: Icons.api_outlined,
              title: 'Backend API URL',
              controller: _apiUrlController,
              onSubmitted: (val) {
                // In a real app, save this to persistent storage
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API URL updated (session only)')),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('Data Management'),
          _buildSettingsCard([
            _buildActionTile(
              icon: Icons.delete_outline,
              title: 'Clear All Contracts',
              color: AppTheme.errorColor,
              onTap: () => _showConfirmDialog('Clear All Contracts', 'This will permanently remove all analyzed contracts.'),
            ),
            _buildDivider(),
            _buildActionTile(
              icon: Icons.download_outlined,
              title: 'Export My Data',
              color: AppTheme.primaryColor,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data exported to JSON successfully')),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('Support & About'),
          _buildSettingsCard([
            _buildActionTile(
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () {},
            ),
            _buildDivider(),
            _buildActionTile(
              icon: Icons.info_outline,
              title: 'About Car Loan Assistant',
              subtitle: 'Version ${AppConfig.appVersion}',
              onTap: () {},
            ),
            _buildDivider(),
            _buildActionTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 32),
          
          Center(
            child: Text(
              'Made with ❤️ for better car deals',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.person, color: Colors.white, size: 35),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'John Doe',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'john.doe@example.com',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: GoogleFonts.poppins(fontSize: 14)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextFieldTile({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required ValueChanged<String> onSubmitted,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: TextField(
        controller: controller,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          border: InputBorder.none,
          fillColor: Colors.transparent,
        ),
        style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.accentColor),
        onSubmitted: onSubmitted,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.primaryColor),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 56, color: Colors.grey.withOpacity(0.1));
  }

  void _showConfirmDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Confirm', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
