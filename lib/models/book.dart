class Book {
  final int id;
  final String title;
  final String writer;
  final String publisher;
  final int year;
  final int stockRemaining;
  final String? coverImage;
  final String? description;

  Book({
    required this.id,
    required this.title,
    required this.writer,
    required this.publisher,
    required this.year,
    required this.stockRemaining,
    this.coverImage,
    this.description,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      writer: json['writer'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      stockRemaining: json['stock_remaining'] as int? ?? 0,
      coverImage: json['cover_image'] as String?,
      description: json['description'] as String?,
    );
  }
}
