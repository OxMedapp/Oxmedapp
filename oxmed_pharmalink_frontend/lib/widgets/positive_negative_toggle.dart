// lib/widgets/positive_negative_toggle.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PositiveNegativeToggle extends StatelessWidget {
  final String label;
  final String? value; // 'positive' or 'negative' or null
  final ValueChanged<String?> onChanged;

  const PositiveNegativeToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        ChoiceChip(
          label: const Text('Positive'),
          selected: value == 'positive',
          onSelected: (selected) => onChanged(selected ? 'positive' : null),
          selectedColor: AppColors.redAccent.withOpacity(0.2),
          labelStyle: TextStyle(color: value == 'positive' ? AppColors.redAccent : null),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Negative'),
          selected: value == 'negative',
          onSelected: (selected) => onChanged(selected ? 'negative' : null),
          selectedColor: AppColors.tealGreen.withOpacity(0.2),
          labelStyle: TextStyle(color: value == 'negative' ? AppColors.tealGreen : null),
        ),
      ],
    );
  }
}