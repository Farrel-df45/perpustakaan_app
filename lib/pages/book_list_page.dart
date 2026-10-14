import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/book_service.dart';
import '../services/loan_service.dart';
import '../widgets/book_card.dart';
import 'book_form_page.dart';

class BookListPage extends StatefulWidget {
  const BookListPage({super.key});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final TextEditingController searchController =
      TextEditingController();

  List<Map<String, dynamic>> books = [];
  bool isLoading = true;
  String? errorMessage;

  bool get isAdmin => AuthService.isAdmin;
  String? get token => AuthService.token;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadBooks({String? search}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await BookService.getBooks(
        search: search,
        token: token,
      );

      final rawData = result['data'];

      if (rawData is List) {
        books = rawData
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        books = [];
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> openBookForm([
    Map<String, dynamic>? book,
  ]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BookFormPage(book: book),
      ),
    );

    if (changed == true && mounted) {
      await loadBooks(search: searchController.text);
    }
  }

  Future<void> deleteBook(Map<String, dynamic> book) async {
    final id = int.tryParse(book['id'].toString());

    if (id == null || token == null) {
      showMessage('Data buku atau token tidak valid.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: Text(
          'Yakin ingin menghapus "${book['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await BookService.deleteBook(
        token: token!,
        id: id,
      );

      if (!mounted) return;

      showMessage('Buku berhasil dihapus.');
      await loadBooks(search: searchController.text);
    } catch (e) {
      if (mounted) {
        showMessage(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> requestLoan(Map<String, dynamic> book) async {
    final id = int.tryParse(book['id'].toString());

    if (id == null || token == null) {
      showMessage('Data buku atau token tidak valid.');
      return;
    }

    final stock =
        int.tryParse(book['stock_available']?.toString() ?? '0') ?? 0;

    if (stock < 1) {
      showMessage('Stok buku sedang habis.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajukan Peminjaman'),
        content: Text(
          'Ajukan peminjaman buku "${book['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ajukan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await LoanService.requestLoan(
        token: token!,
        bookId: id,
      );

      if (!mounted) return;

      showMessage('Pengajuan peminjaman berhasil dikirim.');
      await loadBooks(search: searchController.text);
    } catch (e) {
      if (mounted) {
        showMessage(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Buku'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => loadBooks(
              search: searchController.text,
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => openBookForm(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Buku'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: searchController,
              onSubmitted: (value) => loadBooks(search: value),
              decoration: InputDecoration(
                hintText: 'Cari judul atau penulis buku...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    searchController.clear();
                    loadBooks();
                  },
                  icon: const Icon(Icons.close),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => loadBooks(
                search: searchController.text,
              ),
              child: buildBookContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBookContent() {
    if (isLoading && books.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null && books.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.cloud_off, size: 48),
          const SizedBox(height: 12),
          Center(child: Text(errorMessage!)),
          Center(
            child: TextButton(
              onPressed: () => loadBooks(
                search: searchController.text,
              ),
              child: const Text('Coba Lagi'),
            ),
          ),
        ],
      );
    }

    if (books.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          Icon(Icons.menu_book_outlined, size: 48),
          SizedBox(height: 12),
          Center(child: Text('Buku tidak ditemukan.')),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final book = books[index];

        return BookCard(
          book: book,
          onTap: () => showBookDetail(book),
          action: isAdmin
              ? Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => openBookForm(book),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                      ),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => deleteBook(book),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                      ),
                      label: const Text('Hapus'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                )
              : FilledButton.tonalIcon(
                  onPressed: () => requestLoan(book),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Pinjam Buku'),
                ),
        );
      },
    );
  }

  void showBookDetail(Map<String, dynamic> book) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final coverUrl = book['cover_url']?.toString();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 130,
                      height: 175,
                      child: coverUrl != null && coverUrl.isNotEmpty
                          ? Image.network(
                              coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(
                                Icons.menu_book,
                                size: 70,
                              ),
                            )
                          : const Icon(
                              Icons.menu_book,
                              size: 70,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  book['title']?.toString() ?? 'Tanpa judul',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                detailRow('Penulis', book['author']),
                detailRow('Penerbit', book['publisher']),
                detailRow('Kategori', book['category']),
                detailRow('Rak', book['shelf']),
                detailRow('Total stok', book['stock_total']),
                detailRow('Stok tersedia', book['stock_available']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? '-'),
          ),
        ],
      ),
    );
  }
}