import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String emoji;

  /// Bright end of the category gradient.
  final Color color;

  /// Deep end of the category gradient (keeps white text readable).
  final Color colorDark;

  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.colorDark,
  });

  List<Color> get gradient => [color, colorDark];
}
