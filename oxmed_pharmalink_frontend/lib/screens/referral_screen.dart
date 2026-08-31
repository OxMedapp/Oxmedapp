import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/status_badge.dart';

class ReferralCreatedScreen extends StatelessWidget {
  const ReferralCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Referral created'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.tealGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Referral ID: PH-3427-000274',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.oxfordNavy,
              ),
            ),
            const SizedBox(height: 24),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DetailRow(label: 'Urgency', value: 'Urgent'),
                  Divider(height: 16),
                  const _DetailRow(
                      label: 'Receiving facility',
                      value: 'Korle Bu Teaching Hospital'),
                  Divider(height: 16),
                  const _DetailRow(
                    label: 'Reason for referral',
                    value:
                        'Severe headache, High BP. Fever — urgent evaluation',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // QR code placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: const Center(
                child: const Icon(Icons.qr_code,
                    size: 120, color: AppColors.oxfordNavy),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Show this QR code at the facility',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Send securely',
              icon: Icons.lock_outline,
              onPressed: () {
                Navigator.pushNamed(context, '/tracking');
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Call facility',
                    isPrimary: false,
                    icon: Icons.phone_outlined,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Patient instructions',
                    isPrimary: false,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
