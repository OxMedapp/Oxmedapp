import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class ReferralsTab extends StatefulWidget {
  const ReferralsTab({super.key});

  @override
  _ReferralsTabState createState() => _ReferralsTabState();
}

class _ReferralsTabState extends State<ReferralsTab> {
  List<dynamic> _referrals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReferrals();
  }

  Future<void> _fetchReferrals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.dio.get('/api/referrals');
      setState(() {
        _referrals = response.data['referrals'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load referrals. Please try again.';
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
      onRefresh: _fetchReferrals,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.redAccent),
                  ),
                )
              : _referrals.isEmpty
                  ? const Center(
                      child: Text(
                        'No referrals found',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _referrals.length,
                      itemBuilder: (context, index) {
                        final referral = _referrals[index];
                        final status = referral['status'] ?? 'pending';
                        Color statusColor;
                        switch (status) {
                          case 'completed':
                            statusColor = AppColors.tealGreen;
                            break;
                          case 'accepted':
                            statusColor = AppColors.limeGreen;
                            break;
                          case 'declined':
                            statusColor = AppColors.redAccent;
                            break;
                          default:
                            statusColor = AppColors.urgentOrange;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            onTap: () {
                              Navigator.pushNamed(context, '/tracking');
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.assignment_outlined, color: AppColors.royalBlue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        referral['referral_code'] ?? 'Unknown',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'To: ${referral['facility_name'] ?? 'Unknown facility'}',
                                        style: const TextStyle(color: AppColors.mutedText),
                                      ),
                                      Text(
                                        'Category: ${referral['category'] ?? 'N/A'}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  text: status,
                                  color: statusColor,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}