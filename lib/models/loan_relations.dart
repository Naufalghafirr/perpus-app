import 'book.dart';
import 'user_profile.dart';
import 'paginated_books.dart';

class LoanWithRelations {
  final int id;
  final String loanDate;
  final String? returnDate;
  final String status;
  final Book book;
  final UserProfile user;
  final String? notes;

  LoanWithRelations({
    required this.id,
    required this.loanDate,
    this.returnDate,
    required this.status,
    required this.book,
    required this.user,
    this.notes,
  });

  factory LoanWithRelations.fromJson(Map<String, dynamic> json) {
    final bookData = json['book'] as Map<String, dynamic>? ?? {};
    final userData = json['user'] as Map<String, dynamic>? ?? {};

    return LoanWithRelations(
      id: json['id'] as int,
      loanDate: json['loan_date'] as String? ?? '',
      returnDate: json['return_date'] as String?,
      status: json['status'] as String? ?? 'loaned',
      book: Book.fromJson(bookData),
      user: UserProfile.fromJson(userData),
      notes: json['notes'] as String?,
    );
  }

  bool get isOverdue {
    if (status == 'returned') return false;
    if (returnDate != null) return false;

    try {
      final now = DateTime.now();
      final dueDate = DateTime.parse(returnDate ?? loanDate);
      return now.isAfter(dueDate);
    } catch (_) {
      return false;
    }
  }

  String get formattedLoanDate {
    try {
      final date = DateTime.parse(loanDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return loanDate;
    }
  }

  String? get formattedReturnDate {
    if (returnDate == null) return null;
    try {
      final date = DateTime.parse(returnDate!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return returnDate;
    }
  }
}

class PaginatedLoansResponse {
  final List<LoanWithRelations> loans;
  final Pagination pagination;

  PaginatedLoansResponse({required this.loans, required this.pagination});

  factory PaginatedLoansResponse.fromJson(Map<String, dynamic> json) {
    final loansData = json['data'] as List<dynamic>? ?? [];
    final loans = loansData
        .map(
          (loanJson) =>
              LoanWithRelations.fromJson(loanJson as Map<String, dynamic>),
        )
        .toList();

    final paginationData = json['pagination'] as Map<String, dynamic>? ?? {};
    final pagination = Pagination.fromJson(paginationData);

    return PaginatedLoansResponse(loans: loans, pagination: pagination);
  }
}

class PaginatedUsersResponse {
  final List<UserProfile> users;
  final Pagination pagination;

  PaginatedUsersResponse({required this.users, required this.pagination});

  factory PaginatedUsersResponse.fromJson(Map<String, dynamic> json) {
    final usersData = json['data'] as List<dynamic>? ?? [];
    final users = usersData
        .map(
          (userJson) => UserProfile.fromJson(userJson as Map<String, dynamic>),
        )
        .toList();

    final paginationData = json['pagination'] as Map<String, dynamic>? ?? {};
    final pagination = Pagination.fromJson(paginationData);

    return PaginatedUsersResponse(users: users, pagination: pagination);
  }
}
