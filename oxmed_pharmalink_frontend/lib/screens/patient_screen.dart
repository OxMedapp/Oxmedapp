import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class PatientScreen extends StatefulWidget {
  const PatientScreen({super.key});

  @override
  _PatientScreenState createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  bool _hasNoIdentifier = false;
  bool _consentConfirmed = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Find or register patient'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phone number field
            TextField(
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined),
                suffixIcon:
                    Icon(Icons.check_circle, color: AppColors.tealGreen),
              ),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'NHIS number',
                prefixIcon: Icon(Icons.badge_outlined),
                suffixIcon:
                    Icon(Icons.check_circle, color: AppColors.tealGreen),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Ghana Card number',
                prefixIcon: Icon(Icons.credit_card_outlined),
                suffixIcon:
                    Icon(Icons.check_circle, color: AppColors.tealGreen),
              ),
            ),
            const SizedBox(height: 24),
            // Has no identifier toggle
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.mutedText),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Patient has no identifier'),
                  ),
                  Switch(
                    value: _hasNoIdentifier,
                    onChanged: (val) {
                      setState(() => _hasNoIdentifier = val);
                    },
                    activeThumbColor: AppColors.royalBlue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Consent
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: AppColors.tealGreen),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Consent confirmed'),
                  ),
                  Switch(
                    value: _consentConfirmed,
                    onChanged: (val) {
                      setState(() => _consentConfirmed = val);
                    },
                    activeThumbColor: AppColors.tealGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Continue',
              onPressed: () {
                Navigator.pushNamed(context, '/assessment');
              },
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }
}
