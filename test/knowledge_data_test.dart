import 'package:aneuncheok/data/dummy_data.dart';
import 'package:aneuncheok/models/knowledge_item.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guardrails for the card library. These run on every card, so adding
/// hundreds more cannot silently break ids, categories or layout limits.
void main() {
  // The ids that shipped first. Players' saved progress points at these, so
  // they must never be renamed or removed.
  final legacyIds = {
    for (var i = 1; i <= 12; i++) 'd$i',
    for (var i = 1; i <= 11; i++) 'he$i',
    for (var i = 1; i <= 11; i++) 'f$i',
    for (var i = 1; i <= 10; i++) 'm$i',
    for (var i = 1; i <= 10; i++) 'sa$i',
    for (var i = 1; i <= 11; i++) 'b$i',
  };

  group('categories', () {
    test('ids and names are unique', () {
      final ids = categories.map((c) => c.id).toList();
      final names = categories.map((c) => c.name).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(names.toSet(), hasLength(names.length));
    });

    test('the original six keep their order', () {
      expect(categories.take(6).map((c) => c.id), [
        'daily',
        'health',
        'food',
        'money',
        'safety',
        'body',
      ]);
    });

    test('each category has plenty of cards', () {
      for (final c in categories) {
        expect(
          getItemsByCategory(c.id).length,
          greaterThanOrEqualTo(15),
          reason: '${c.id} is too small',
        );
      }
    });

    test('every card belongs to a known category', () {
      final known = categories.map((c) => c.id).toSet();
      for (final item in knowledgeItems) {
        expect(known, contains(item.categoryId), reason: item.id);
      }
    });
  });

  group('ids', () {
    test('are unique and well formed', () {
      final ids = knowledgeItems.map((i) => i.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(RegExp(r'^[a-z]+\d+$').hasMatch(id), isTrue, reason: id);
      }
    });

    test('use one prefix per category', () {
      final prefixOf = <String, String>{};
      for (final item in knowledgeItems) {
        final prefix = RegExp(r'^[a-z]+').firstMatch(item.id)!.group(0)!;
        expect(
          prefixOf.putIfAbsent(item.categoryId, () => prefix),
          prefix,
          reason: '${item.id} does not match its category prefix',
        );
      }
      expect(
        prefixOf.values.toSet(),
        hasLength(prefixOf.length),
        reason: 'two categories share an id prefix',
      );
    });

    test('every original id still exists', () {
      final ids = knowledgeItems.map((i) => i.id).toSet();
      expect(legacyIds.difference(ids), isEmpty);
    });
  });

  group('content', () {
    test('every card has an emoji, title and body', () {
      for (final item in knowledgeItems) {
        expect(item.emoji, isNotNull, reason: item.id);
        expect(item.emoji!.trim(), isNotEmpty, reason: item.id);
        expect(item.title.trim(), isNotEmpty, reason: item.id);
        expect(item.content.trim(), isNotEmpty, reason: item.id);
      }
    });

    test('titles and bodies fit the card layout', () {
      for (final item in knowledgeItems) {
        expect(
          item.title.length,
          inInclusiveRange(2, 24),
          reason: '${item.id} title: ${item.title}',
        );
        expect(
          item.content.length,
          inInclusiveRange(20, 200),
          reason: '${item.id} body is ${item.content.length} chars',
        );
      }
    });

    test('text is cleanly formatted', () {
      for (final item in knowledgeItems) {
        for (final text in [item.title, item.content]) {
          expect(text, text.trim(), reason: '${item.id} has stray spaces');
          expect(
            text.contains('  '),
            isFalse,
            reason: '${item.id} double space',
          );
          expect(text.contains('\n'), isFalse, reason: '${item.id} newline');
          expect(
            text.contains(RegExp('TODO|FIXME|XXX')),
            isFalse,
            reason: '${item.id} has a placeholder',
          );
        }
      }
    });

    test('titles and bodies are not duplicated', () {
      final titles = knowledgeItems.map((i) => i.title.trim()).toList();
      final bodies = knowledgeItems.map((i) => i.content.trim()).toList();
      expect(
        titles.toSet(),
        hasLength(titles.length),
        reason: 'duplicate title',
      );
      expect(
        bodies.toSet(),
        hasLength(bodies.length),
        reason: 'duplicate body',
      );
    });

    test('a source, when given, is not blank', () {
      for (final item in knowledgeItems.where((i) => i.source != null)) {
        expect(item.source!.trim(), isNotEmpty, reason: item.id);
      }
    });

    test('the share text carries the title and body', () {
      final KnowledgeItem item = knowledgeItems.first;
      expect(item.shareText, contains(item.title));
      expect(item.shareText, contains(item.content));
    });
  });

  test('the library is big enough to keep players busy', () {
    expect(knowledgeItems.length, greaterThanOrEqualTo(200));
  });
}
