import 'package:flutter/material.dart';

class ScoreboardCell extends StatelessWidget {
  final String text;
  final bool isBold;
  final Color? color;
  final String? deltaText;
  final Color? deltaColor;
  final VoidCallback? onLongPress;

  const ScoreboardCell({
    super.key,
    required this.text,
    this.isBold = false,
    this.color,
    this.deltaText,
    this.deltaColor,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );

    Widget content = Container(
      height: 60,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text.rich(
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: text.isEmpty ? '\u200B' : text),
            if (deltaText != null)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Text(
                  deltaText!,
                  style: textTheme.bodySmall?.copyWith(color: deltaColor),
                ),
              ),
          ],
        ),
      ),
    );

    if (onLongPress != null) {
      content = GestureDetector(
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
