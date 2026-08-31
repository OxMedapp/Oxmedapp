// lib/screens/ai_review_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/status_badge.dart';

class AIReviewScreen extends StatelessWidget {
  const AIReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the review data from arguments
    final review = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (review == null) {
      // Fallback if no data (should not happen)
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No review data available')),
      );
    }

    // Extract fields with defaults
    final summary = review['draft_summary'] ?? 'No summary provided.';
    final warningSigns = List<String>.from(review['detected_warning_signs'] ?? []);
    final missingInfo = List<String>.from(review['missing_questions'] ?? []);
    final urgency = (review['suggested_urgency'] ?? 'routine').toString().toLowerCase();
    final serviceType = review['recommended_service_type'] ?? 'Not specified';
    final explanation = review['explanation'] ?? 'No explanation provided.';
    final confidence = (review['confidence'] ?? 0.0).toDouble();
    final model = review['model_version'] ?? 'unknown';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Text('AI-assisted referral summary'),
            SizedBox(width: 8),
            Icon(Icons.auto_awesome, color: AppColors.royalBlue, size: 20),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clinical Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(summary),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Warning signs
            if (warningSigns.isNotEmpty)
              AppCard(
                color: AppColors.redAccent.withOpacity(0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.redAccent),
                        SizedBox(width: 8),
                        Text('Warning Signs', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.redAccent)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...warningSigns.map((flag) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(flag)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Missing info
            if (missingInfo.isNotEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.urgentOrange),
                        SizedBox(width: 8),
                        Text('Missing Information', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...missingInfo.map((q) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.question_mark, color: AppColors.urgentOrange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(q)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Urgency & Service
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    child: Column(
                      children: [
                        const Text('Urgency', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        StatusBadge(
                          text: urgency.toUpperCase(),
                          color: _urgencyColor(urgency),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    child: Column(
                      children: [
                        const Text('Service', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          serviceType,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Explanation
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rationale', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(explanation),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${confidence.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                  ),
                  Text(
                    'Model: $model',
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppButton(
              label: 'Confirm & Continue',
              icon: Icons.check_circle_outline,
              onPressed: () {
                // Navigate to routing (smart routing) or referral creation
                Navigator.pushNamed(context, '/routing');
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Edit Assessment',
                    isPrimary: false,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Regenerate AI',
                    isPrimary: false,
                    onPressed: () {
                      // Could re-trigger AI review
                      // For simplicity, we'll just pop and let them re-submit
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Final decision must be made by an authorized professional.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'emergency':
        return AppColors.redAccent;
      case 'urgent':
        return AppColors.urgentOrange;
      default:
        return AppColors.tealGreen;
    }
  }
}