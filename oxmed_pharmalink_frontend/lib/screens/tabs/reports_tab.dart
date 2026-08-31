import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  _ReportsTabState createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.dio.get('/api/stats/coordinator');
      setState(() {
        _stats = response.data['stats'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load reports. Please try again.';
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text(_error!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.redAccent),
                  ),
                )
              : _stats == null
                  ? const Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Operational Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.oxfordNavy,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ReportCard(
                            title: 'Total Encounters',
                            value: '${_stats!['total_encounters'] ?? 0}',
                            icon: Icons.people_outline,
                            color: AppColors.royalBlue,
                          ),
                          _ReportCard(
                            title: 'Total Referrals',
                            value: '${_stats!['total_referrals'] ?? 0}',
                            icon: Icons.assignment_outlined,
                            color: AppColors.limeGreen,
                          ),
                          _ReportCard(
                            title: 'Total Follow-ups',
                            value: '${_stats!['total_follow_ups'] ?? 0}',
                            icon: Icons.event_available_outlined,
                            color: AppColors.tealGreen,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Referrals by Status',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          ...(_stats!['referrals_by_status'] as List? ?? []).map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(item['status'] ?? 'unknown'),
                                  ),
                                  Text(
                                    '${item['count'] ?? 0}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          const Text(
                            'Operational Gaps',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text('Encounters without referral: ${_stats!['operational_gaps']?['encounters_without_referral'] ?? 0}'),
                          Text('Pending referrals overdue: ${_stats!['operational_gaps']?['pending_referrals_overdue'] ?? 0}'),
                        ],
                      ),
                    ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.mutedText)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}