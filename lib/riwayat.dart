import 'package:flutter/material.dart';

import 'service/api_client.dart';
import 'models/loan_history.dart';
import 'models/loan_relations.dart';
import 'models/paginated_books.dart';

class HistoryPage extends StatefulWidget {
  final ApiClient apiClient;
  final String? token;
  final bool isAdmin;

  const HistoryPage({
    super.key,
    required this.apiClient,
    required this.token,
    required this.isAdmin,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<PaginatedLoansResponse> _future;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusOptions = ['all', 'loaned', 'returned', 'overdue'];
  String _selectedStatus = 'all';
  int _currentPage = 1;
  final int _perPage = 10;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<PaginatedLoansResponse> _load() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      return PaginatedLoansResponse(
        loans: [],
        pagination: Pagination(
          currentPage: 1,
          perPage: _perPage,
          totalData: 0,
          totalPages: 0,
        ),
      );
    }

    final searchQuery = _searchController.text.trim();
    final statusFilter = _selectedStatus == 'all' ? null : _selectedStatus;

    if (widget.isAdmin) {
      return await widget.apiClient.getAdminLoans(
        token: token,
        page: _currentPage,
        limit: _perPage,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        status: statusFilter,
      );
    }

    return await widget.apiClient.getLoans(
      token: token,
      page: _currentPage,
      limit: _perPage,
      search: searchQuery.isNotEmpty ? searchQuery : null,
      status: statusFilter,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _markReturned(LoanHistoryItem item) async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      return;
    }

    final confirmed = await _showReturnConfirmationDialog(item);
    if (!confirmed) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      if (widget.isAdmin) {
        await widget.apiClient.returnAdminLoan(token: token, id: item.id);
      } else {
        await widget.apiClient.markLoanReturned(token: token, id: item.id);
      }
      await _refresh();
      messenger.showSnackBar(
        const SnackBar(content: Text('Status peminjaman diperbarui')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e')),
      );
    }
  }

  Future<bool> _showReturnConfirmationDialog(LoanHistoryItem item) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Konfirmasi Pengembalian'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Apakah Anda yakin ingin mengembalikan buku:'),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Peminjam: ${item.borrower}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3BA9),
                  ),
                  child: const Text('Ya, Kembalikan'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token == null || widget.token!.isEmpty) {
      return Container(
        color: const Color(0xFFF5F7FA),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(height: 12),
                Text(
                  'Masuk terlebih dahulu untuk melihat riwayat peminjaman.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F7FA),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<PaginatedLoansResponse>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Gagal memuat riwayat',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Coba lagi'),
                  ),
                ],
              );
            }

            final response = snapshot.data;
            if (response == null) {
              return const Center(child: Text('Tidak ada data'));
            }

            // Convert LoanWithRelations to LoanHistoryItem
            final items = response.loans.map((loan) {
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
            final active = items
                .where((e) => e.status == LoanStatus.active)
                .toList();
            final late = items
                .where((e) => e.status == LoanStatus.late)
                .toList();
            final returned = items
                .where((e) => e.status == LoanStatus.returned)
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Peminjaman',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lihat semua riwayat peminjaman buku',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _HistoryStatCard(
                        color: const Color(0xFF2563EB),
                        icon: Icons.schedule,
                        label: 'Peminjaman Aktif',
                        value: active.length.toString(),
                      ),
                      _HistoryStatCard(
                        color: const Color(0xFFEF4444),
                        icon: Icons.error_outline,
                        label: 'Terlambat',
                        value: late.length.toString(),
                      ),
                      _HistoryStatCard(
                        color: const Color(0xFF16A34A),
                        icon: Icons.check_circle_outline,
                        label: 'Dikembalikan',
                        value: returned.length.toString(),
                      ),
                    ],
                  ),
                  if (late.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Terlambat (${late.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final item in late) ...[
                      _HistoryLoanCard(
                        item: item,
                        onReturn: widget.isAdmin
                            ? () => _markReturned(item)
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  if (active.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.schedule, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Text(
                          'Peminjaman Aktif (${active.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final item in active) ...[
                      _HistoryLoanCard(
                        item: item,
                        onReturn: widget.isAdmin
                            ? () => _markReturned(item)
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  if (returned.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dikembalikan (${returned.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final item in returned) ...[
                      _HistoryLoanCard(item: item),
                      const SizedBox(height: 16),
                    ],
                  ],
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        'Belum ada riwayat peminjaman.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryStatCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String value;
  final String label;

  const _HistoryStatCard({
    required this.color,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryLoanCard extends StatelessWidget {
  final LoanHistoryItem item;
  final Future<void> Function()? onReturn;

  const _HistoryLoanCard({required this.item, this.onReturn});

  Color get statusColor {
    switch (item.status) {
      case LoanStatus.active:
        return const Color(0xFF2563EB);
      case LoanStatus.late:
        return const Color(0xFFEF4444);
      case LoanStatus.returned:
        return const Color(0xFF16A34A);
    }
  }

  String get statusText {
    switch (item.status) {
      case LoanStatus.active:
        return 'Aktif';
      case LoanStatus.late:
        return 'Terlambat';
      case LoanStatus.returned:
        return 'Dikembalikan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLate = item.status == LoanStatus.late;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.borrower.isNotEmpty
                        ? item.borrower[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.status == LoanStatus.late
                                      ? Icons.error_outline
                                      : item.status == LoanStatus.returned
                                      ? Icons.check_circle_outline
                                      : Icons.schedule,
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.borrower,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_note_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tanggal Pinjam ${item.startDate}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jatuh Tempo',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          item.dueDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (isLate) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE7E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFEF4444),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Buku ini sudah melewati tanggal pengembalian. Segera hubungi peminjam.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (onReturn != null && item.status != LoanStatus.returned) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await onReturn!();
                  },
                  icon: const Icon(Icons.keyboard_return, size: 16),
                  label: const Text(
                    'Tandai dikembalikan',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
