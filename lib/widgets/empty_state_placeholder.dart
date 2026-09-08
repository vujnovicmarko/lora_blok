import 'package:flutter/material.dart';

class EmptyStatePlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData? actionIcon;

  const EmptyStatePlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: 8),
            if (actionIcon != null && subtitle.contains('+'))
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: subtitle.split('+')[0]),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          actionIcon,
                          size: (textTheme.bodyMedium?.fontSize ?? 14) + 2,
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                    TextSpan(text: subtitle.split('+').skip(1).join('+')),
                  ],
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              )
            else
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
