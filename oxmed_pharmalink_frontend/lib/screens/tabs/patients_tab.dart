import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class PatientsTab extends StatefulWidget {
  const PatientsTab({super.key});

  @override
  _PatientsTabState createState() => _PatientsTabState();
}

class _PatientsTabState extends State<PatientsTab> {
  List<dynamic> _patients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.dio.get('/api/patients');
      setState(() {
        _patients = response.data['patients'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load patients. Please try again.';
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
      onRefresh: _fetchPatients,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.redAccent),
                  ),
                )
              : _patients.isEmpty
                  ? const Center(
                      child: Text(
                        'No patients found',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _patients.length,
                      itemBuilder: (context, index) {
                        final patient = _patients[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Patient ${patient['temporary_token']}'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Phone: ${patient['phone'] ?? 'N/A'}'),
                                      Text('Consent: ${patient['consent_status']}'),
                                      Text('Created: ${patient['created_at'] ?? 'N/A'}'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, color: AppColors.royalBlue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patient['temporary_token'] ?? 'Unknown',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Phone: ${patient['phone'] ?? 'N/A'}',
                                        style: const TextStyle(color: AppColors.mutedText),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  text: patient['consent_status'] ?? 'pending',
                                  color: patient['consent_status'] == 'granted'
                                      ? AppColors.tealGreen
                                      : AppColors.urgentOrange,
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