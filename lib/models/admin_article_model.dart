enum ArticleStatus {
  semua('Semua'),
  diterbitkan('Diterbitkan'),
  draf('Draf');

  final String label;
  const ArticleStatus(this.label);
}

class AdminArticleModel {
  final String id;
  String title;
  String category;
  String date;
  String content;
  ArticleStatus status;

  /// Firestore document id (equals [id] in demo mode).
  final String? fsDocId;

  AdminArticleModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.content,
    required this.status,
    this.fsDocId,
  });

  String get backendId => fsDocId ?? id;

  AdminArticleModel copyWith({
    String? id,
    String? title,
    String? category,
    String? date,
    String? content,
    ArticleStatus? status,
    String? fsDocId,
  }) {
    return AdminArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      content: content ?? this.content,
      status: status ?? this.status,
      fsDocId: fsDocId ?? this.fsDocId,
    );
  }
}
