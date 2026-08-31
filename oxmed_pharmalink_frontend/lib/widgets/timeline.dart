import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TimelineItem {
  final String title;
  final bool completed;
  final bool current;
  final String? timestamp;

  TimelineItem({
    required this.title,
    this.completed = false,
    this.current = false,
    this.timestamp,
  });
}

class Timeline extends StatelessWidget {
  final List<TimelineItem> items;

  const Timeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isLast = index == items.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.completed
                        ? AppColors.tealGreen
                        : item.current
                            ? AppColors.royalBlue
                            : AppColors.borderGrey,
                    border: item.current
                        ? Border.all(color: AppColors.royalBlue, width: 3)
                        : null,
                  ),
                  child: item.completed
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: item.completed
                        ? AppColors.tealGreen
                        : AppColors.borderGrey,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: item.current
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: item.completed
                            ? AppColors.tealGreen
                            : item.current
                                ? AppColors.oxfordNavy
                                : AppColors.mutedText,
                      ),
                    ),
                    if (item.timestamp != null)
                      Text(
                        item.timestamp!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}