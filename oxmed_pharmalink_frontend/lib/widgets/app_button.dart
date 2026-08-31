import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return SizedBox(
        width: width,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon) : null,
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.oxfordNavy,
            foregroundColor: foregroundColor ?? AppColors.white,
          ),
        ),
      );
    } else {
      return SizedBox(
        width: width,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon) : null,
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.oxfordNavy,
            side: BorderSide(color: backgroundColor ?? AppColors.oxfordNavy),
          ),
        ),
      );
    }
  }
}