import 'package:flutter/material.dart';
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

  Color get _pageBg => _darkMode ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA);
  Color get _appBarBg => _darkMode ? const Color(0xFF111827) : Colors.white;
  Color get _cardBg => _darkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _primaryText => _darkMode ? const Color(0xFFF9FAFB) : AppTheme.textPrimary;
  Color get _secondaryText => _darkMode ? const Color(0xFF9CA3AF) : AppTheme.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: _primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0.5,
        scrolledUnderElevation: 0.5,
        backgroundColor: _appBarBg,
        foregroundColor: _primaryText,
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
            _buildDivider(),
            _buildDropdownTile(
              icon: Icons.monetization_on_outlined,
              title: 'Currency',
              value: _selectedCurrency,
              items: ['USD (\$)', 'INR (Rs)', 'EUR (€)', 'GBP (£)', 'CAD (\$)'],
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
              style: TextStyle(
                fontSize: 12,
                color: _secondaryText,
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _secondaryText,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      color: _cardBg,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryText,
                    ),
                  ),
                  Text(
                    'john.doe@example.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: _secondaryText,
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
      color: _cardBg,
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
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: _primaryText),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: _secondaryText),
      ),
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
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: _primaryText),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        dropdownColor: _cardBg,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(fontSize: 14, color: _primaryText),
            ),
          );
        }).toList(),
        onChanged: onChanged,
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
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color ?? _primaryText,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: _secondaryText))
          : null,
      trailing: Icon(Icons.chevron_right, size: 20, color: _secondaryText),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      color: _darkMode ? Colors.white12 : Colors.grey.withOpacity(0.1),
    );
  }

  void _showConfirmDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: _primaryText),
        ),
        content: Text(message, style: TextStyle(color: _secondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _secondaryText)),
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
