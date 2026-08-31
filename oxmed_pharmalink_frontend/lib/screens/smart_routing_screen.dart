import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/facility_card.dart';
import '../widgets/status_badge.dart';
import '../models/facility.dart';

class SmartRoutingScreen extends StatelessWidget {
  const SmartRoutingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final facilities = [
      Facility(
          name: 'Korle Bu Teaching Hospital', distance: 7.2, travelTime: 13),
      Facility(
          name: '37 Military Hospital',
          distance: 12.5,
          travelTime: 22,
          isAvailable: false),
      Facility(name: 'Ridge Hospital', distance: 3.1, travelTime: 8),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recommended referral options'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filters
            const Row(
              children: [
                const StatusBadge(
                  text: 'Urgency: Urgent',
                  color: AppColors.urgentOrange,
                ),
                SizedBox(width: 8),
                const StatusBadge(
                  text: 'Service required',
                  color: AppColors.royalBlue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mock map
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Stack(
                children: [
                  // Simplified map: grid lines and pins
                  CustomPaint(
                    painter: _MapPainter(),
                    size: Size.infinite,
                  ),
                  const Center(
                    child: const Icon(Icons.location_pin,
                        size: 40, color: AppColors.redAccent),
                  ),
                  const Positioned(
                    top: 40,
                    left: 40,
                    child: const Icon(Icons.local_hospital,
                        size: 30, color: AppColors.royalBlue),
                  ),
                  const Positioned(
                    bottom: 30,
                    right: 40,
                    child: const Icon(Icons.local_hospital,
                        size: 30, color: AppColors.tealGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Facility list
            ...facilities.map((facility) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FacilityCard(
                    facility: facility,
                    onSelect: () {
                      Navigator.pushNamed(context, '/referral');
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderGrey.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
