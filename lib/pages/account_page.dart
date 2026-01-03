import 'package:flutter/material.dart';

import '../service/api_client.dart';
import '../models/user_profile.dart';
import '../models/auth_result.dart';
import '../models/loan_history.dart';
import '../models/loan_relations.dart';
import '../models/paginated_books.dart';
import 'login_page.dart';
import '../register_page.dart';

class AccountPage extends StatefulWidget {
  final UserProfile? user;
  final ApiClient apiClient;
  final String? token;
  final Future<void> Function(AuthResult result) onLoggedIn;
  final Future<void> Function(UserProfile updatedUser) onProfileUpdated;
  final Future<void> Function() onLogout;

  const AccountPage({
    super.key,
    this.user,
    required this.apiClient,
    required this.token,
    required this.onLoggedIn,
    required this.onProfileUpdated,
    required this.onLogout,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late Future<PaginatedLoansResponse> _loansFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loansFuture = _loadLoans();
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
      _loansFuture = _loadLoans();
    });
  }

  Future<bool> _showLogoutConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Konfirmasi Keluar'),
              content: const Text(
                'Apakah Anda yakin ingin keluar dari aplikasi?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                  child: const Text('Ya, Keluar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.user != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isLoggedIn) ...[
              _buildLoginPrompt(),
              const SizedBox(height: 24),
            ] else ...[
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildStatsCards(),
              const SizedBox(height: 24),
              _buildRecentActivity(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3BA9), Color(0xFF4F70FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum Login',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Masuk untuk mengakses profil dan aktivitas peminjaman',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(
                      apiClient: widget.apiClient,
                      onLoggedIn: widget.onLoggedIn,
                      onProfileUpdated: widget.onProfileUpdated,
                      onLogout: widget.onLogout,
                    ),
                  ),
                );
                // Refresh after login if needed
                if (result != null && mounted) {
                  _refresh();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3BA9),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Masuk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RegisterPage(apiClient: widget.apiClient),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A3BA9),
                side: const BorderSide(color: Color(0xFF1A3BA9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Daftar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3BA9), Color(0xFF4F70FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(Icons.person_rounded, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.user!.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.user!.email,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3BA9).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              widget.user!.role == 'administrator' ? 'Admin' : 'User',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A3BA9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return FutureBuilder<PaginatedLoansResponse>(
      future: _loansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final loansResponse = snapshot.data;
        if (loansResponse == null) {
          return const Center(child: Text('Tidak ada data pinjaman'));
        }

        // Convert LoanWithRelations to LoanHistoryItem
        final loans = loansResponse.loans.map((loan) {
          final statusRaw = loan.status;
          final status = switch (statusRaw) {
            'overdue' => LoanStatus.late,
            'returned' => LoanStatus.returned,
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

        final activeLoans = loans
            .where((e) => e.status == LoanStatus.active)
            .length;
        late final int lateLoans;
        late final int returnedLoans;

        lateLoans = loans.where((e) => e.status == LoanStatus.late).length;
        returnedLoans = loans
            .where((e) => e.status == LoanStatus.returned)
            .length;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.menu_book_outlined,
                label: 'Dipinjam',
                value: activeLoans.toString(),
                color: const Color(0xFF1A3BA9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.history,
                label: 'Riwayat',
                value: returnedLoans.toString(),
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.error_outline,
                label: 'Terlambat',
                value: lateLoans.toString(),
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
              fontWeight: FontWeight.w700,
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
                return const Text('Gagal memuat data');
              }

              final loansResponse = snapshot.data;
              if (loansResponse == null) {
                return const Text('Tidak ada data');
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

              final recentLoans = loans.take(3).toList();

              if (recentLoans.isEmpty) {
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(
                    apiClient: widget.apiClient,
                    onLoggedIn: widget.onLoggedIn,
                    onProfileUpdated: widget.onProfileUpdated,
                    onLogout: widget.onLogout,
                  ),
                ),
              );
              if (mounted) _refresh();
            },
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit Profil'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A3BA9),
              side: const BorderSide(color: Color(0xFF1A3BA9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () async {
              final confirmed = await _showLogoutConfirmationDialog();
              if (!confirmed) return;

              await widget.onLogout();
              if (mounted) _refresh();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final LoanHistoryItem loan;

  const _ActivityTile({required this.loan});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    Color backgroundColor;

    switch (loan.status) {
      case LoanStatus.active:
        statusColor = const Color(0xFF16A34A);
        statusText = 'Aktif';
        backgroundColor = const Color(0xFFD1FAE5);
        break;
      case LoanStatus.late:
        statusColor = const Color(0xFFEF4444);
        statusText = 'Terlambat';
        backgroundColor = const Color(0xFFFEE2E2);
        break;
      case LoanStatus.returned:
        statusColor = const Color(0xFF1A3BA9);
        statusText = 'Dikembalikan';
        backgroundColor = const Color(0xFFE8EDFB);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
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
              loan.title.isNotEmpty ? loan.title[0].toUpperCase() : '?',
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
                  loan.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loan.startDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
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
