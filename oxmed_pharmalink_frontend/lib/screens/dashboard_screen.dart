import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/app_card.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await ApiClient.dio.get('/api/stats/coordinator');
      setState(() {
        _stats = response.data['stats'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Fallback to mock data if backend not reachable
        _stats = {
          'total_referrals': 12,
          'total_follow_ups': 5,
          'total_encounters': 20,
        };
      });
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    // For demo, we just switch the content area or navigate.
    // Implement actual navigation later.
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        Navigator.pushNamed(context, '/patients');
        break;
      case 2:
        Navigator.pushNamed(context, '/referrals');
        break;
      case 3:
        Navigator.pushNamed(context, '/reports');
        break;
      case 4:
        Navigator.pushNamed(context, '/more');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.oxfordNavy,
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.assignment_outlined,
                          label: 'New assessment',
                          value: '${_stats?['total_encounters'] ?? 0}',
                          color: AppColors.royalBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people_outline,
                          label: 'Active referrals',
                          value: '${_stats?['total_referrals'] ?? 0}',
                          color: AppColors.limeGreen,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.event_available_outlined,
                    label: 'Follow-ups due',
                    value: '${_stats?['total_follow_ups'] ?? 0}',
                    color: AppColors.tealGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.emergency_outlined,
                    label: 'Emergency pathway',
                    value:
                        '${_stats?['operational_gaps']?['encounters_without_referral'] ?? 0}',
                    color: AppColors.redAccent,
                    isEmergency: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppCard(
              onTap: () => Navigator.pushNamed(context, '/patient'),
              child: const Row(
                children: [
                  Icon(Icons.add_circle_outline, color: AppColors.royalBlue),
                  SizedBox(width: 12),
                  Text(
                    'New Assessment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isEmergency;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isEmergency ? AppColors.redAccent : AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}
