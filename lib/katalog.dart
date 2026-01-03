import 'package:flutter/material.dart';

import 'service/api_client.dart';
import 'models/book.dart';
import 'models/paginated_books.dart';

class CatalogPage extends StatefulWidget {
  final ApiClient apiClient;
  final Future<bool> Function(Book book) onBorrow;
  final bool isAdmin;
  final String? token;

  const CatalogPage({
    super.key,
    required this.apiClient,
    required this.onBorrow,
    required this.isAdmin,
    required this.token,
  });

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late Future<PaginatedBooksResponse> _booksFuture;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['Semua Kategori'];
  String _selectedCategory = 'Semua Kategori';
  bool _isGrid = true;
  String _sortMode = 'judul_asc';
  int _currentPage = 1;
  final int _perPage = 10;

  @override
  void initState() {
    super.initState();
    _booksFuture = _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _currentPage = 1;
      _booksFuture = _loadBooks();
    });
  }

  void _nextPage() {
    setState(() {
      _currentPage++;
      _booksFuture = _loadBooks();
    });
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _booksFuture = _loadBooks();
      });
    }
  }

  void _updateCategories(List<Book> books) {
    final categorySet = <String>{};
    for (final b in books) {
      if (b.publisher.trim().isEmpty) continue;
      categorySet.add(b.publisher);
    }
    final nextCategories = ['Semua Kategori', ...categorySet.toList()..sort()];
    if (nextCategories.length == _categories.length &&
        List<String>.generate(
          nextCategories.length,
          (i) => nextCategories[i],
        ).every(
          (value) => value == _categories[nextCategories.indexOf(value)],
        )) {
      return;
    }
    setState(() {
      _categories
        ..clear()
        ..addAll(nextCategories);
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = 'Semua Kategori';
      }
    });
  }

  Future<PaginatedBooksResponse> _loadBooks() async {
    PaginatedBooksResponse response;
    if (widget.isAdmin && widget.token != null && widget.token!.isNotEmpty) {
      response = await widget.apiClient.getAdminBooks(
        token: widget.token!,
        page: _currentPage,
        limit: _perPage,
      );
    } else {
      response = await widget.apiClient.getBooks(
        page: _currentPage,
        limit: _perPage,
      );
    }
    if (mounted) {
      _updateCategories(response.books);
    }
    return response;
  }

  Future<void> _showBookDetail(Book book) async {
    if (widget.isAdmin) {
      final changed =
          await showDialog<bool>(
            context: context,
            builder: (context) => ManageBookDialog(
              apiClient: widget.apiClient,
              token: widget.token,
              book: book,
            ),
          ) ??
          false;

      if (changed && mounted) {
        _refresh();
      }
    } else {
      final shouldBorrow =
          await showDialog<bool>(
            context: context,
            builder: (context) => BookDetailDialog(book: book),
          ) ??
          false;

      if (shouldBorrow && mounted) {
        final success = await widget.onBorrow(book);
        if (success && mounted) {
          _refresh();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 0,
            child: Container(
              constraints: const BoxConstraints(minHeight: 140, maxHeight: 160),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A3BA9), Color(0xFF4F70FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Katalog Buku',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'Temukan buku favorit Anda',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.filter_list_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF64748B),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Cari judul atau penulis...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF64748B,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.clear_rounded,
                                    size: 14,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sort_rounded,
                                  size: 16,
                                  color: Color(0xFF1A3BA9),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Urutkan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  _sortMode == 'judul_desc'
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_up_rounded,
                                  size: 16,
                                  color: Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isGrid = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _isGrid
                                        ? const Color(0xFF1A3BA9)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Icon(
                                    Icons.grid_view_rounded,
                                    size: 16,
                                    color: _isGrid
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isGrid = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: !_isGrid
                                        ? const Color(0xFF1A3BA9)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Icon(
                                    Icons.list_rounded,
                                    size: 16,
                                    color: !_isGrid
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isAdmin) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final created =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (context) => ManageBookDialog(
                                    apiClient: widget.apiClient,
                                    token: widget.token,
                                    book: null,
                                  ),
                                ) ??
                                false;
                            if (created && mounted) {
                              _refresh();
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Tambah Buku Baru'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3BA9),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _refresh();
                        await _booksFuture;
                      },
                      child: FutureBuilder<PaginatedBooksResponse>(
                        future: _booksFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1A3BA9),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.error_outline,
                                      color: Color(0xFFEF4444),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Gagal memuat data',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF1E293B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    snapshot.error.toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _refresh,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A3BA9),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Coba lagi'),
                                  ),
                                ],
                              ),
                            );
                          }

                          final response = snapshot.data!;
                          final books = response.books;
                          final pagination = response.pagination;
                          final query = _searchController.text.trim();
                          final filteredByQuery = query.isEmpty
                              ? books
                              : books.where((b) {
                                  final title = b.title.toLowerCase();
                                  final writer = b.writer.toLowerCase();
                                  final searchQuery = query.toLowerCase();
                                  return title.contains(searchQuery) ||
                                      writer.contains(searchQuery);
                                }).toList();
                          final filteredByCategory =
                              _selectedCategory == 'Semua Kategori'
                              ? filteredByQuery
                              : filteredByQuery
                                    .where(
                                      (b) => b.publisher == _selectedCategory,
                                    )
                                    .toList();

                          final filtered = List<Book>.from(filteredByCategory)
                            ..sort((a, b) {
                              switch (_sortMode) {
                                case 'judul_desc':
                                  return b.title.toLowerCase().compareTo(
                                    a.title.toLowerCase(),
                                  );
                                case 'judul_asc':
                                default:
                                  return a.title.toLowerCase().compareTo(
                                    b.title.toLowerCase(),
                                  );
                              }
                            });

                          if (filtered.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.search_off_rounded,
                                      color: Color(0xFF64748B),
                                      size: 48,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada buku yang ditemukan',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              int crossAxisCount = 2;
                              double childAspectRatio = 0.65;
                              double crossAxisSpacing = 16;
                              double mainAxisSpacing = 16;

                              if (width >= 1200) {
                                crossAxisCount = 5;
                                childAspectRatio = 0.6;
                              } else if (width >= 1000) {
                                crossAxisCount = 4;
                                childAspectRatio = 0.62;
                              } else if (width >= 700) {
                                crossAxisCount = 3;
                                childAspectRatio = 0.65;
                              } else if (width >= 500) {
                                crossAxisCount = 2;
                                childAspectRatio = 0.7;
                              } else {
                                crossAxisCount = 2;
                                childAspectRatio = 0.75;
                                crossAxisSpacing = 12;
                                mainAxisSpacing = 12;
                              }

                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  24,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Text(
                                        query.isNotEmpty
                                            ? 'Hasil pencarian "${query}": ${filtered.length} buku'
                                            : 'Menampilkan ${filtered.length} dari ${books.length} buku',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (_isGrid)
                                      Expanded(
                                        child: GridView.builder(
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: crossAxisCount,
                                                crossAxisSpacing:
                                                    crossAxisSpacing,
                                                mainAxisSpacing:
                                                    mainAxisSpacing,
                                                childAspectRatio:
                                                    childAspectRatio,
                                              ),
                                          itemCount: filtered.length,
                                          itemBuilder: (context, index) {
                                            final book = filtered[index];
                                            return BookCard(
                                              book: book,
                                              onTap: () =>
                                                  _showBookDetail(book),
                                              isGrid: true,
                                            );
                                          },
                                        ),
                                      )
                                    else
                                      Expanded(
                                        child: ListView(
                                          children: [
                                            for (final book in filtered)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                child: BookCard(
                                                  book: book,
                                                  onTap: () =>
                                                      _showBookDetail(book),
                                                  isGrid: false,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
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

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final bool isGrid;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8EFF7), Color(0xFFF1F5F9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      alignment: Alignment.center,
                      child:
                          book.coverImage != null && book.coverImage!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              child: Image.network(
                                book.coverImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, _, __) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1A3BA9),
                                          Color(0xFF4F70FF),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        book.title.isNotEmpty
                                            ? book.title[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1A3BA9),
                                    Color(0xFF4F70FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  book.title.isNotEmpty
                                      ? book.title[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: book.stockRemaining > 0
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          book.stockRemaining > 0 ? 'Tersedia' : 'Habis',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          book.writer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: book.stockRemaining > 0
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Stok: ${book.stockRemaining}',
                              style: TextStyle(
                                fontSize: 11,
                                color: book.stockRemaining > 0
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                              ),
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
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8EFF7), Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: book.coverImage != null && book.coverImage!.isNotEmpty
                      ? Image.network(
                          book.coverImage!,
                          width: 60,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1A3BA9),
                                    Color(0xFF4F70FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  book.title.isNotEmpty
                                      ? book.title[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A3BA9), Color(0xFF4F70FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              book.title.isNotEmpty
                                  ? book.title[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: book.stockRemaining > 0
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            book.stockRemaining > 0 ? 'Tersedia' : 'Habis',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.writer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 14,
                                color: book.stockRemaining > 0
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stok: ${book.stockRemaining}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: book.stockRemaining > 0
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          book.publisher,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookDetailDialog extends StatelessWidget {
  final Book book;

  const BookDetailDialog({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final isAvailable = book.stockRemaining > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, minHeight: 0),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child:
                            book.coverImage != null &&
                                book.coverImage!.isNotEmpty
                            ? Image.network(
                                book.coverImage!,
                                width: 120,
                                height: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (context, _, __) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1A3BA9),
                                          Color(0xFF4F70FF),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        book.title.isNotEmpty
                                            ? book.title[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1A3BA9),
                                      Color(0xFF4F70FF),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    book.title.isNotEmpty
                                        ? book.title[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.writer,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0EAFF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  book.publisher.isEmpty
                                      ? 'Umum'
                                      : book.publisher,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1A3BA9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isAvailable ? 'Tersedia' : 'Habis',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isAvailable
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF1F5FE),
                        const Color(0xFFE8EFF7).withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1A3BA9).withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A3BA9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Deskripsi Buku',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        book.description != null &&
                                book.description!.trim().isNotEmpty
                            ? book.description!
                            : 'Deskripsi buku belum tersedia. Silakan cek detail di perpustakaan.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Stok Tersedia',
                        value: '${book.stockRemaining} buku',
                        color: const Color(0xFF059669),
                      ),
                      const Divider(height: 20),
                      _InfoRow(
                        icon: Icons.tag_outlined,
                        label: 'ID Buku',
                        value: 'ID-${book.id.toString().padLeft(4, '0')}',
                        color: const Color(0xFF1A3BA9),
                      ),
                      const Divider(height: 20),
                      _InfoRow(
                        icon: Icons.book_outlined,
                        label: 'ISBN',
                        value: 'Tidak tersedia',
                        color: Colors.grey.shade600,
                      ),
                      const Divider(height: 20),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tahun Terbit',
                        value: book.year > 0
                            ? '${book.year}'
                            : 'Tidak diketahui',
                        color: const Color(0xFFDC2626),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Tutup'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: isAvailable
                              ? () {
                                  Navigator.of(context).pop(true);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Pinjam Buku'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ManageBookDialog extends StatefulWidget {
  final ApiClient apiClient;
  final String? token;
  final Book? book;

  const ManageBookDialog({
    super.key,
    required this.apiClient,
    required this.token,
    required this.book,
  });

  @override
  State<ManageBookDialog> createState() => _ManageBookDialogState();
}

class _ManageBookDialogState extends State<ManageBookDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _writerController;
  late TextEditingController _publisherController;
  late TextEditingController _yearController;
  late TextEditingController _isbnController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;
  late TextEditingController _coverImageController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _titleController = TextEditingController(text: book?.title ?? '');
    _writerController = TextEditingController(text: book?.writer ?? '');
    _publisherController = TextEditingController(text: book?.publisher ?? '');
    _yearController = TextEditingController(
      text: book != null && book.year > 0 ? book.year.toString() : '',
    );
    _isbnController = TextEditingController();
    _stockController = TextEditingController(
      text: book != null ? book.stockRemaining.toString() : '',
    );
    _descriptionController = TextEditingController(
      text: book?.description ?? '',
    );
    _coverImageController = TextEditingController(text: book?.coverImage ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _writerController.dispose();
    _publisherController.dispose();
    _yearController.dispose();
    _isbnController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _coverImageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.token == null || widget.token!.isEmpty) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _submitting = true;
    });

    try {
      final year = int.tryParse(_yearController.text.trim()) ?? 0;
      final stock = int.tryParse(_stockController.text.trim()) ?? 0;
      if (widget.book == null) {
        await widget.apiClient.createBook(
          token: widget.token!,
          title: _titleController.text.trim(),
          writer: _writerController.text.trim(),
          publisher: _publisherController.text.trim(),
          year: year,
          isbn: _isbnController.text.trim(),
          stock: stock,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          coverImage: _coverImageController.text.trim().isEmpty
              ? null
              : _coverImageController.text.trim(),
        );
      } else {
        await widget.apiClient.updateBook(
          token: widget.token!,
          id: widget.book!.id,
          title: _titleController.text.trim(),
          writer: _writerController.text.trim(),
          publisher: _publisherController.text.trim(),
          year: year,
          isbn: _isbnController.text.trim(),
          stock: stock,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          coverImage: _coverImageController.text.trim().isEmpty
              ? null
              : _coverImageController.text.trim(),
        );
      }
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    if (widget.book == null) return;
    if (widget.token == null || widget.token!.isEmpty) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _submitting = true;
    });

    try {
      await widget.apiClient.deleteBook(
        token: widget.token!,
        id: widget.book!.id,
      );
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.book != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Ubah Buku' : 'Tambah Buku',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Judul'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _writerController,
                  decoration: const InputDecoration(labelText: 'Penulis'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _publisherController,
                  decoration: const InputDecoration(labelText: 'Penerbit'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(labelText: 'Tahun terbit'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _isbnController,
                  decoration: const InputDecoration(labelText: 'ISBN'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _coverImageController,
                  decoration: const InputDecoration(
                    labelText: 'URL Gambar Sampul (opsional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Buku',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isEdit)
                      TextButton(
                        onPressed: _submitting ? null : _delete,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                        ),
                        child: const Text('Hapus'),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(_submitting ? 'Menyimpan...' : 'Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BorrowRequest {
  final int quantity;
  final DateTime dueDate;

  BorrowRequest({required this.quantity, required this.dueDate});
}
