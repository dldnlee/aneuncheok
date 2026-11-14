import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aneuncheok/data/dummy_data.dart';
import 'package:aneuncheok/main.dart';

/// Phone-sized surface so the whole category grid is built (GridView is lazy).
Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MyApp());
}

void main() {
  testWidgets('home screen shows title, shuffle button and all categories',
      (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('아는척'), findsOneWidget);
    expect(find.text('랜덤 상식'), findsOneWidget);
    for (final category in categories) {
      expect(find.text(category.name), findsOneWidget);
    }
  });

  testWidgets('tapping a category opens its first knowledge card',
      (WidgetTester tester) async {
    await pumpApp(tester);

    final category = categories.first;
    final items = getItemsByCategory(category.id);

    await tester.tap(find.text(category.name));
    await tester.pumpAndSettle();

    expect(find.text(items.first.title), findsOneWidget);
    expect(find.text('1 / ${items.length}'), findsOneWidget);
  });

  testWidgets('shuffle button opens a feed with every item',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('랜덤 상식'));
    await tester.pumpAndSettle();

    expect(find.text('1 / ${knowledgeItems.length}'), findsOneWidget);
    expect(find.byIcon(Icons.shuffle), findsWidgets);
  });

  testWidgets('back button returns to the home screen',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text(categories.first.name));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('랜덤 상식'), findsOneWidget);
  });
}
