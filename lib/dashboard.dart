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

  Future<void> _refresh() async {
    setState(() {
      _booksFuture = widget.apiClient.getBooks(limit: 100);
      _loansFuture = _loadLoans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF1A3BA9),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: 24),
              _buildStatsCards(),
              const SizedBox(height: 24),
              _buildRecentBooks(),
              const SizedBox(height: 24),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final userName = widget.user?.name ?? 'User';
    final userRole = widget.user?.role ?? 'user';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3BA9), Color(0xFF4F70FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3BA9).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Text(
              userRole == 'administrator' ? 'Administrator' : 'User',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return FutureBuilder(
      future: Future.wait([_booksFuture, _loansFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Gagal memuat data'));
        }

        final booksResponse = snapshot.data![0] as PaginatedBooksResponse;
        final loansResponse = snapshot.data![1] as PaginatedLoansResponse;

        final totalBooks = booksResponse.pagination.totalData;
        final activeLoans = loansResponse.loans
            .where((loan) => loan.status == 'loaned')
            .length;
        final returnedLoans = loansResponse.loans
            .where((loan) => loan.status == 'returned')
            .length;
        final overdueLoans = loansResponse.loans
            .where((loan) => loan.status == 'overdue')
            .length;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.menu_book,
                    label: 'Total Buku',
                    value: totalBooks.toString(),
                    color: const Color(0xFF1A3BA9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.bookmark,
                    label: 'Dipinjam',
                    value: activeLoans.toString(),
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.history,
                    label: 'Dikembalikan',
                    value: returnedLoans.toString(),
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.warning,
                    label: 'Terlambat',
                    value: overdueLoans.toString(),
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentBooks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Buku Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to catalog
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: Color(0xFF1A3BA9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<PaginatedBooksResponse>(
            future: _booksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Gagal memuat buku'));
              }

              final booksResponse = snapshot.data;
              if (booksResponse == null || booksResponse.books.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Tidak ada buku tersedia',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                );
              }

              final recentBooks = booksResponse.books.take(4).toList();

              return SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentBooks.length,
                  itemBuilder: (context, index) {
                    final book = recentBooks[index];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      child: _BookCard(book: book),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivitas Terbaru',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<PaginatedLoansResponse>(
            future: _loansFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Gagal memuat aktivitas'));
              }

              final loansResponse = snapshot.data;
              if (loansResponse == null || loansResponse.loans.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Belum ada aktivitas peminjaman',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                );
              }

              final recentLoans = loansResponse.loans.take(3).toList();

              return Column(
                children: recentLoans
                    .map((loan) => _ActivityTile(loan: loan))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3BA9), Color(0xFF4F70FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: book.coverImage != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        book.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.menu_book,
                            color: Colors.white,
                            size: 40,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.menu_book,
                      color: Colors.white,
                      size: 40,
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.writer,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${book.stockRemaining}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final dynamic loan;

  const _ActivityTile({required this.loan});

  @override
  Widget build(BuildContext context) {
    final status = loan.status.toString();
    final statusColor = switch (status) {
      'loaned' => const Color(0xFF2563EB),
      'returned' => const Color(0xFF16A34A),
      'overdue' => const Color(0xFFEF4444),
      _ => Colors.grey,
    };

    final statusText = switch (status) {
      'loaned' => 'Dipinjam',
      'returned' => 'Dikembalikan',
      'overdue' => 'Terlambat',
      _ => 'Unknown',
    };

    final statusIcon = switch (status) {
      'loaned' => Icons.menu_book,
      'returned' => Icons.check_circle,
      'overdue' => Icons.warning,
      _ => Icons.help,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.book.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loan.user.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
