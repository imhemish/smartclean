import "package:flutter/material.dart";

class PopupMenuItemWithIcon extends PopupMenuItem<String> {
  PopupMenuItemWithIcon(
      {super.key,
      required this.textValue,
      required this.icon,
      required this.color}) : super(
        value: textValue,
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 8),
            Text(textValue),
          ],
        )
      );

  final String textValue;
  final IconData icon;
  final Color color;
}
