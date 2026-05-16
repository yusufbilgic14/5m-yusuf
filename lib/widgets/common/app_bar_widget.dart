import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// Modern ve ortak AppBar widget'ı
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double height;

  const ModernAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.height = kToolbarHeight + 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? [
            const Color(0xFF181F2A),
            AppConstants.primaryColor.withValues(alpha: 0.85),
          ]
        : [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withValues(alpha: 0.85),
          ];
    final boxShadowColor = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : AppConstants.primaryColor.withValues(alpha: 0.13);
    final textColor = const Color(0xFFDDB822);
    final subtitleColor = const Color(0xFFDDB822).withValues(alpha: 0.85);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: boxShadowColor,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) leading!,
                if (leading != null) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: centerTitle
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: AppConstants.fontSizeXLarge,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: centerTitle
                            ? TextAlign.center
                            : TextAlign.start,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: AppConstants.fontSizeMedium,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: centerTitle
                              ? TextAlign.center
                              : TextAlign.start,
                        ),
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
