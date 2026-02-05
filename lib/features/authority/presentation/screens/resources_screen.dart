import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Available Resources'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildResourceCard(
            'Police Units',
            '15 Available',
            Icons.local_police,
            AppTheme.citizenAccent,
          ),
          const SizedBox(height: 12),
          _buildResourceCard(
            'Fire Services',
            '8 Available',
            Icons.local_fire_department,
            AppTheme.primaryRed,
          ),
          const SizedBox(height: 12),
          _buildResourceCard(
            'Ambulances',
            '12 Available',
            Icons.local_hospital,
            AppTheme.primaryGreen,
          ),
          const SizedBox(height: 12),
          _buildResourceCard(
            'Volunteers',
            '45 On Duty',
            Icons.people,
            AppTheme.primaryOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(String title, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  status,
                  style: const TextStyle(
                    color: AppTheme.neutralGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.neutralGray),
        ],
      ),
    );
  }
}
