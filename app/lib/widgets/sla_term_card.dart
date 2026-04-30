// SLA Term Card Widget

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/theme.dart';
import '../models/sla_data.dart';

class SlaTermCard extends StatelessWidget {
  final SlaTermItem term;

  const SlaTermCard({super.key, required this.term});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getIconColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIcon(),
                color: _getIconColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    term.label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    term.value ?? 'Not specified',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (term.iconType) {
      case 'percent':
        return FontAwesomeIcons.percent;
      case 'calendar':
        return FontAwesomeIcons.calendarDays;
      case 'dollar':
        return FontAwesomeIcons.dollarSign;
      case 'car':
        return FontAwesomeIcons.car;
      case 'warning':
        return FontAwesomeIcons.triangleExclamation;
      case 'alert':
        return FontAwesomeIcons.circleExclamation;
      case 'shopping':
        return FontAwesomeIcons.cartShopping;
      case 'tools':
        return FontAwesomeIcons.wrench;
      case 'shield':
        return FontAwesomeIcons.shield;
      case 'insurance':
        return FontAwesomeIcons.fileContract;
      default:
        return FontAwesomeIcons.fileLines;
    }
  }

  Color _getIconColor() {
    switch (term.iconType) {
      case 'percent':
        return AppTheme.infoColor;
      case 'dollar':
        return AppTheme.successColor;
      case 'warning':
      case 'alert':
        return AppTheme.warningColor;
      default:
        return AppTheme.primaryColor;
    }
  }
}
