import 'package:flutter/material.dart';

import 'service/api_client.dart';
import 'models/user_profile.dart';
import 'models/book.dart';
import 'models/paginated_books.dart';
import 'models/loan_history.dart';
import 'models/loan_relations.dart';

class DashboardPage extends StatefulWidget {
  final UserProfile? user;
  final ApiClient apiClient;
  final String? token;

  const DashboardPage({
    super.key,
    this.user,
    required this.apiClient,
    required this.token,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<PaginatedBooksResponse> _booksFuture;
  late Future<PaginatedLoansResponse> _loansFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = widget.apiClient.getBooks(limit: 100);
    _loansFuture = _loadLoans();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token ||
        oldWidget.user?.id != widget.user?.id ||
        oldWidget.user?.role != widget.user?.role) {
      _refresh();
    }
  }

  Future<PaginatedLoansResponse> _loadLoans() {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      return Future.value(
        PaginatedLoansResponse(
          loans: [],
          pagination: Pagination(
            currentPage: 1,
            perPage: 10,
            totalData: 0,
            totalPages: 0,
          ),
        ),
      );
    }
    final role = widget.user?.role ?? 'user';
    if (role == 'administrator') {
      return widget.apiClient.getAdminLoans(token: token);
    }
    return widget.apiClient.getLoans(token: token);
  }

  void _refresh() {
    setState(() {
      _booksFuture = widget.apiClient.getBooks(limit: 100);
      _loansFuture = _loadLoans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Selamat datang di Sistem Perpustakaan Digital',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
            if (widget.user != null) ...[
              const SizedBox(height: 4),
              Text(
                'Halo, ${widget.user!.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF1A3BA9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FutureBuilder<PaginatedBooksResponse>(
              future: _booksFuture,
              builder: (context, bookSnapshot) {
                if (bookSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (bookSnapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gagal memuat data dashboard',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _refresh,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3BA9),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  );
                }

                final response = bookSnapshot.data!;
                final books = response.books;
                final totalBooks = books.length;
                final totalAvailableCopies = books.fold<int>(
                  0,
                  (sum, b) => sum + b.stockRemaining,
                );

                return FutureBuilder<PaginatedLoansResponse>(
                  future: _loansFuture,
                  builder: (context, loanSnapshot) {
                    if (loanSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (loanSnapshot.hasError) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gagal memuat data peminjaman',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _refresh,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A3BA9),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      );
                    }

                    final loansResponse = loanSnapshot.data;
                    if (loansResponse == null) {
                      return const Center(
                        child: Text('Tidak ada data pinjaman'),
                      );
                    }

                    // Convert LoanWithRelations to LoanHistoryItem
                    final loans = loansResponse.loans.map((loan) {
                      final statusRaw = loan.status;
                      final status = switch (statusRaw) {
                        'overdue' => LoanStatus.late,
                        'returned' => LoanStatus.returned,
                        'loaned' => LoanStatus.active,
                        _ => LoanStatus.active,
                      };

                      return LoanHistoryItem(
                        id: loan.id,
                        title: loan.book.title,
                        borrower: loan.user.name,
                        email: loan.user.email,
                        startDate: loan.formattedLoanDate,
                        dueDate: loan.formattedReturnDate ?? '-',
                        status: status,
                      );
                    }).toList();

                    final borrowedTitles = loans
                        .where((e) => e.status == LoanStatus.active)
                        .length;
                    final lateCount = loans
                        .where((e) => e.status == LoanStatus.late)
                        .length;

                    return _DashboardContent(
                      totalBooks: totalBooks,
                      totalAvailableCopies: totalAvailableCopies,
                      borrowedTitles: borrowedTitles,
                      lateCount: lateCount,
                      books: books,
                      loans: loans,
                      onRefresh: _refresh,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final int totalBooks;
  final int totalAvailableCopies;
  final int borrowedTitles;
  final int lateCount;
  final List<Book> books;
  final List<LoanHistoryItem> loans;
  final VoidCallback onRefresh;

  const _DashboardContent({
    required this.totalBooks,
    required this.totalAvailableCopies,
    required this.borrowedTitles,
    required this.lateCount,
    required this.books,
    required this.loans,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final categories = _buildCategories(books);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            DashboardStatCard(
              icon: Icons.menu_book_outlined,
              iconColor: const Color(0xFF1A3BA9),
              backgroundColor: const Color(0xFFE8EDFB),
              value: totalBooks.toString(),
              label: 'Total Buku',
              badgeText: '+12%',
              badgeColor: const Color(0xFF16A34A),
            ),
            DashboardStatCard(
              icon: Icons.trending_up,
              iconColor: Colors.white,
              backgroundColor: const Color(0xFF16A34A),
              value: totalAvailableCopies.toString(),
              label: 'Tersedia',
              badgeText: '$totalAvailableCopies buku',
              badgeColor: const Color(0xFF16A34A),
            ),
            DashboardStatCard(
              icon: Icons.person_outline,
              iconColor: Colors.white,
              backgroundColor: const Color(0xFF7C3AED),
              value: borrowedTitles.toString(),
              label: 'Dipinjam',
              badgeText: borrowedTitles > 0 ? 'Aktif' : 'Belum ada',
              badgeColor: const Color(0xFF7C3AED),
            ),
            DashboardStatCard(
              icon: Icons.error_outline,
              iconColor: Colors.white,
              backgroundColor: const Color(0xFFEF4444),
              value: lateCount.toString(),
              label: 'Terlambat',
              badgeText: lateCount > 0 ? 'Perlu tindakan' : 'Aman',
              badgeColor: const Color(0xFFEF4444),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final recentItems = loans
                .take(3)
                .map((loan) => _mapLoanToRecentLoanItem(loan))
                .toList();
            final recentWidget = RecentLoansCard(items: recentItems);
            final popularWidget = PopularCategoriesCard(items: categories);

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: recentWidget),
                  const SizedBox(width: 16),
                  SizedBox(width: 260, child: popularWidget),
                ],
              );
            }

            return Column(
              children: [
                recentWidget,
                const SizedBox(height: 16),
                popularWidget,
              ],
            );
          },
        ),
      ],
    );
  }

  static List<PopularCategoryItem> _buildCategories(List<Book> books) {
    final Map<String, int> counts = {};
    for (final book in books) {
      final key = book.publisher.isEmpty ? 'Lainnya' : book.publisher;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(5)
        .map((e) => PopularCategoryItem(name: e.key, value: e.value))
        .toList();
  }

  static RecentLoanItem _mapLoanToRecentLoanItem(LoanHistoryItem loan) {
    switch (loan.status) {
      case LoanStatus.late:
        return RecentLoanItem(
          title: loan.title,
          borrower: loan.borrower,
          date: loan.startDate,
          statusText: 'Terlambat',
          statusColor: const Color(0xFFEF4444),
          statusBackground: const Color(0xFFFDE7E9),
        );
      case LoanStatus.returned:
        return RecentLoanItem(
          title: loan.title,
          borrower: loan.borrower,
          date: loan.startDate,
          statusText: 'Dikembalikan',
          statusColor: const Color(0xFF2563EB),
          statusBackground: const Color(0xFFE5EDFF),
        );
      case LoanStatus.active:
        return RecentLoanItem(
          title: loan.title,
          borrower: loan.borrower,
          date: loan.startDate,
          statusText: 'Aktif',
          statusColor: const Color(0xFF16A34A),
          statusBackground: const Color(0xFFE4F6EC),
        );
    }
  }
}

class DashboardStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String value;
  final String label;
  final String badgeText;
  final Color badgeColor;

  const DashboardStatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.value,
    required this.label,
    required this.badgeText,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class RecentLoanItem {
  final String title;
  final String borrower;
  final String date;
  final String statusText;
  final Color statusColor;
  final Color statusBackground;

  RecentLoanItem({
    required this.title,
    required this.borrower,
    required this.date,
    required this.statusText,
    required this.statusColor,
    required this.statusBackground,
  });
}

class RecentLoansCard extends StatelessWidget {
  final List<RecentLoanItem> items;

  const RecentLoansCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peminjaman Terbaru',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ringkasan aktivitas peminjaman terbaru',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.schedule, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in items) ...[
            _RecentLoanTile(item: item),
            if (item != items.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _RecentLoanTile extends StatelessWidget {
  final RecentLoanItem item;

  const _RecentLoanTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDFB),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3BA9),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.borrower,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  item.date,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.statusBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.statusText,
              style: TextStyle(
                color: item.statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PopularCategoryItem {
  final String name;
  final int value;

  PopularCategoryItem({required this.name, required this.value});
}

class PopularCategoriesCard extends StatelessWidget {
  final List<PopularCategoryItem> items;

  const PopularCategoriesCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final maxValue = items.isEmpty
        ? 1
        : items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final colors = [
      const Color(0xFF1A3BA9),
      const Color(0xFF16A34A),
      const Color(0xFFF97316),
      const Color(0xFF7C3AED),
      const Color(0xFFEC4899),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Populer',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Berdasarkan jumlah buku per kategori',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              'Belum ada data kategori',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == items.length - 1 ? 0 : 12,
                    ),
                    child: _CategoryBar(
                      item: items[i],
                      maxValue: maxValue,
                      color: colors[i % colors.length],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final PopularCategoryItem item;
  final int maxValue;
  final Color color;

  const _CategoryBar({
    required this.item,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = item.value / maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.value.toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
