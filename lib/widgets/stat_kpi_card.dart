import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'flat_card.dart';

class StatKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final double? progress;
  final Color? progressColor;
  final VoidCallback? onTap;

  const StatKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.badgeText,
    this.badgeColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.progress,
    this.progressColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FlatCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? iconColor).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: badgeColor ?? iconColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: isDark ? AppColors.cardDarkElevated : AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor ?? iconColor),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
