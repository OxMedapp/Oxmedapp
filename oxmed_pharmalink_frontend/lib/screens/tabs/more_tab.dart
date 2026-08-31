import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    ApiClient.clearAuthToken();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          onTap: () {
            // Show user info (could fetch from /api/auth/me)
          },
          child: const Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.royalBlue),
              SizedBox(width: 12),
              Text('Profile'),
              Spacer(),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () {
            // Settings
          },
          child: const Row(
            children: [
              Icon(Icons.settings_outlined, color: AppColors.royalBlue),
              SizedBox(width: 12),
              Text('Settings'),
              Spacer(),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () {
            // About
          },
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.royalBlue),
              SizedBox(width: 12),
              Text('About'),
              Spacer(),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.redAccent,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}