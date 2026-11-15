import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/knowledge_item.dart';
import 'cards/body_cards.dart';
import 'cards/daily_cards.dart';
import 'cards/digital_cards.dart';
import 'cards/environment_cards.dart';
import 'cards/food_cards.dart';
import 'cards/health_cards.dart';
import 'cards/language_cards.dart';
import 'cards/money_cards.dart';
import 'cards/safety_cards.dart';
import 'cards/science_cards.dart';

/// Categories in the order they appear on the home screen.
final List<Category> categories = [
  const Category(
    id: 'daily',
    name: '생활',
    emoji: '🏠',
    color: Color(0xFFFF8A8A),
    colorDark: Color(0xFFE5484D),
  ),
  const Category(
    id: 'health',
    name: '건강',
    emoji: '💪',
    color: Color(0xFF5BB0FF),
    colorDark: Color(0xFF2563EB),
  ),
  const Category(
    id: 'food',
    name: '음식',
    emoji: '🍔',
    color: Color(0xFFFFB84D),
    colorDark: Color(0xFFF2680C),
  ),
  const Category(
    id: 'money',
    name: '돈',
    emoji: '💰',
    color: Color(0xFF34D399),
    colorDark: Color(0xFF059669),
  ),
  const Category(
    id: 'safety',
    name: '안전',
    emoji: '🚨',
    color: Color(0xFFB794FF),
    colorDark: Color(0xFF7C3AED),
  ),
  const Category(
    id: 'body',
    name: '인체',
    emoji: '🧬',
    color: Color(0xFFFF7CBF),
    colorDark: Color(0xFFDB2777),
  ),
  const Category(
    id: 'science',
    name: '과학',
    emoji: '🔬',
    color: Color(0xFF22D3EE),
    colorDark: Color(0xFF0E7490),
  ),
  const Category(
    id: 'digital',
    name: '디지털',
    emoji: '💻',
    color: Color(0xFF818CF8),
    colorDark: Color(0xFF4338CA),
  ),
  const Category(
    id: 'environment',
    name: '환경',
    emoji: '🌱',
    color: Color(0xFF84CC16),
    colorDark: Color(0xFF3F6212),
  ),
  const Category(
    id: 'language',
    name: '말과 글',
    emoji: '💬',
    color: Color(0xFF2DD4BF),
    colorDark: Color(0xFF0F766E),
  ),
];

/// Every card. To add content, add items to the matching file in `cards/`
/// (or create a new category above plus a new file there).
final List<KnowledgeItem> knowledgeItems = [
  ...dailyCards,
  ...healthCards,
  ...foodCards,
  ...moneyCards,
  ...safetyCards,
  ...bodyCards,
  ...scienceCards,
  ...digitalCards,
  ...environmentCards,
  ...languageCards,
];

List<KnowledgeItem> getItemsByCategory(String categoryId) {
  return knowledgeItems.where((item) => item.categoryId == categoryId).toList();
}
