import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;
  final IconData? icon;

  StatusChip({
    super.key,
    required this.label,
    required dynamic textColor,
    required dynamic bgColor,
    this.icon,
  })  : textColor = textColor is Color ? textColor : Color(textColor as int),
        bgColor = bgColor is Color ? bgColor : Color(bgColor as int);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
