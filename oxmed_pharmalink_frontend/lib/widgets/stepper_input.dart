// lib/widgets/stepper_input.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StepperInput extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final String unit;

  const StepperInput({
    super.key,
    required this.label,
    required this.value,
    this.min = 0,
    this.max = 300,
    this.step = 1,
    required this.onChanged,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
          color: AppColors.royalBlue,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderGrey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$value$unit',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
          color: AppColors.royalBlue,
        ),
      ],
    );
  }
}