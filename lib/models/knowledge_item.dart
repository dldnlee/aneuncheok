class KnowledgeItem {
  final String id;
  final String categoryId;
  final String title;
  final String content;
  final String? source;

  const KnowledgeItem({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.content,
    this.source,
  });
}
