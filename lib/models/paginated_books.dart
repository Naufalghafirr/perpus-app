import 'book.dart';

class Pagination {
  final int currentPage;
  final int perPage;
  final int totalData;
  final int totalPages;

  Pagination({
    required this.currentPage,
    required this.perPage,
    required this.totalData,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] as int? ?? 1,
      perPage: json['perPage'] as int? ?? 10,
      totalData: json['totalData'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
  bool get isFirstPage => currentPage == 1;
  bool get isLastPage => currentPage == totalPages;
}

class PaginatedBooksResponse {
  final List<Book> books;
  final Pagination pagination;

  PaginatedBooksResponse({required this.books, required this.pagination});

  factory PaginatedBooksResponse.fromJson(Map<String, dynamic> json) {
    final booksData = json['data'] as List<dynamic>? ?? [];
    final books = booksData
        .map((bookJson) => Book.fromJson(bookJson as Map<String, dynamic>))
        .toList();

    final paginationData = json['pagination'] as Map<String, dynamic>? ?? {};
    final pagination = Pagination.fromJson(paginationData);

    return PaginatedBooksResponse(books: books, pagination: pagination);
  }
}
