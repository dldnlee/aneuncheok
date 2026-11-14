class KnowledgeItem {
  final String id;
  final String categoryId;
  final String title;
  final String content;
  final String? source;

  /// Big "sticker" emoji for the card. Falls back to the category emoji.
  final String? emoji;

  const KnowledgeItem({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.content,
    this.source,
    this.emoji,
  });

  /// Text copied to the clipboard by the share button.
  String get shareText => '$title\n$content\n\n- 아는척 😎';
}
