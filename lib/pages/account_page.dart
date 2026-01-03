import 'package:flutter/material.dart';

import '../service/api_client.dart';
import '../models/user_profile.dart';
import '../models/auth_result.dart';
import '../models/loan_history.dart';
import '../models/loan_relations.dart';
import '../models/paginated_books.dart';
import 'login_page.dart';
import '../register_page.dart';
import 'edit_profile_page.dart';

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
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.user!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.user!.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              widget.user!.role == 'administrator' ? 'Administrator' : 'User',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Additional Info
          if (widget.user!.phone_number != null || widget.user!.address != null)
            Column(
              children: [
                if (widget.user!.phone_number != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.user!.phone_number!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (widget.user!.address != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.user!.address!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      user: widget.user!,
                      apiClient: widget.apiClient,
                      token: widget.token!,
                      onProfileUpdated: widget.onProfileUpdated,
                    ),
                  ),
                );
                if (result == true) {
                  _refresh();
                }
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Profil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A3BA9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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

class _ActivityTile extends StatelessWidget {
  final LoanHistoryItem loan;

  const _ActivityTile({required this.loan});

  @override
  Widget build(BuildContext context) {
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
              color: _getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${loan.startDate} - ${loan.dueDate}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 10,
                color: _getStatusColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (loan.status) {
      case LoanStatus.active:
        return const Color(0xFF1A3BA9);
      case LoanStatus.late:
        return const Color(0xFFEF4444);
      case LoanStatus.returned:
        return const Color(0xFF16A34A);
    }
  }

  IconData _getStatusIcon() {
    switch (loan.status) {
      case LoanStatus.active:
        return Icons.menu_book;
      case LoanStatus.late:
        return Icons.error_outline;
      case LoanStatus.returned:
        return Icons.check_circle_outline;
    }
  }

  String _getStatusText() {
    switch (loan.status) {
      case LoanStatus.active:
        return 'Aktif';
      case LoanStatus.late:
        return 'Terlambat';
      case LoanStatus.returned:
        return 'Dikembalikan';
    }
  }
}
