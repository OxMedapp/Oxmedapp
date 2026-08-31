import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/timeline.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timelineItems = [
      TimelineItem(
          title: 'Created', completed: true, timestamp: '26 Aug 2026, 10:15'),
      TimelineItem(
          title: 'Received', completed: true, timestamp: '26 Aug 2026, 10:19'),
      TimelineItem(
          title: 'Accepted', completed: true, timestamp: '26 Aug 2026, 10:22'),
      TimelineItem(
          title: 'Arrived', completed: true, timestamp: '26 Aug 2026, 10:45'),
      TimelineItem(
          title: 'Seen', completed: true, timestamp: '26 Aug 2026, 11:05'),
      TimelineItem(title: 'Follow-up', current: true, timestamp: 'Pending'),
      TimelineItem(title: 'Closed', timestamp: 'Pending'),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Referral journey'),
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
            const Text(
              'Referral ID: PH-3427-000274',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.oxfordNavy,
              ),
            ),
            const SizedBox(height: 24),
            Timeline(items: timelineItems),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Contact patient',
                    isPrimary: false,
                    icon: Icons.phone_outlined,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Add follow-up',
                    isPrimary: false,
                    icon: Icons.event,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Connect to telemedicine',
              isPrimary: false,
              icon: Icons.video_call_outlined,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Escalate overdue referral',
              isPrimary: false,
              backgroundColor: AppColors.redAccent,
              foregroundColor: AppColors.redAccent,
              icon: Icons.warning_amber_outlined,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
