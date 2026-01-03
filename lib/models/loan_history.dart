enum LoanStatus { active, late, returned }

class LoanHistoryItem {
  final int id;
  final String title;
  final String borrower;
  final String email;
  final String startDate;
  final String dueDate;
  final LoanStatus status;

  const LoanHistoryItem({
    required this.id,
    required this.title,
    required this.borrower,
    required this.email,
    required this.startDate,
    required this.dueDate,
    required this.status,
  });

  factory LoanHistoryItem.fromJson(Map<String, dynamic> json) {
    final book = json['book'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    final statusRaw = json['status'] as String? ?? 'loaned';
    final status = switch (statusRaw) {
      'overdue' => LoanStatus.late,
      'returned' => LoanStatus.returned,
      _ => LoanStatus.active,
    };

    String formatDate(String value) {
      if (value.length < 10) return value;
      final y = value.substring(0, 4);
      final m = value.substring(5, 7);
      final d = value.substring(8, 10);
      return '$d/$m/$y';
    }

    final loanDateRaw = json['loan_date']?.toString() ?? '';
    final returnDateRaw = json['return_date']?.toString() ?? '';

    return LoanHistoryItem(
      id: json['id'] as int,
      title: book?['title'] as String? ?? 'Tanpa judul',
      borrower: user?['name'] as String? ?? '',
      email: user?['email'] as String? ?? '',
      startDate: loanDateRaw.isNotEmpty ? formatDate(loanDateRaw) : '-',
      dueDate: returnDateRaw.isNotEmpty ? formatDate(returnDateRaw) : '-',
      status: status,
    );
  }
}
