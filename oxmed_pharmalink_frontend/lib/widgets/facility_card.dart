import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/facility.dart';
import 'app_card.dart';

class FacilityCard extends StatelessWidget {
  final Facility facility;
  final VoidCallback? onSelect;

  const FacilityCard({
    super.key,
    required this.facility,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onSelect,
      child: Row(
        children: [
          const Icon(Icons.local_hospital, color: AppColors.royalBlue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${facility.distance} km',
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${facility.travelTime} min',
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (facility.isAvailable)
            const Icon(Icons.check_circle, color: AppColors.tealGreen, size: 24),
        ],
      ),
    );
  }
}