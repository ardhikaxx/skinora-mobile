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

  AdminArticleModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.content,
    required this.status,
  });

  AdminArticleModel copyWith({
    String? id,
    String? title,
    String? category,
    String? date,
    String? content,
    ArticleStatus? status,
  }) {
    return AdminArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      content: content ?? this.content,
      status: status ?? this.status,
    );
  }
}
