import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Home', Icons.home_outlined, Icons.home),
      ('Patients', Icons.people_outline, Icons.people),
      ('Referrals', Icons.assignment_outlined, Icons.assignment),
      ('Reports', Icons.bar_chart_outlined, Icons.bar_chart),
      ('More', Icons.more_horiz, Icons.more_horiz),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final selected = currentIndex == index;
            return InkWell(
              onTap: () => onTap(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.royalBlue.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        selected ? items[index].$3 : items[index].$2,
                        color: selected ? AppColors.royalBlue : AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[index].$1,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: selected ? AppColors.royalBlue : AppColors.mutedText,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}