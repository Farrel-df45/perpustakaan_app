import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/book_service.dart';
import '../services/loan_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/book_card.dart';
import 'book_list_page.dart';
import 'student_loan_page.dart';
import 'login_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  bool isLoading = true;
  String? errorMessage;

  int totalBooks = 0;
  int totalLoans = 0;
  List<Map<String, dynamic>> latestBooks = [];

  String get studentName =>
      AuthService.user?['name']?.toString() ?? 'Siswa';

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final token = AuthService.token;

    if (token == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Sesi login tidak ditemukan. Silakan login kembali.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        BookService.getBooks(token: token),
        LoanService.getLoans(token: token),
      ]);

      final bookResult = results[0];
      final loanResult = results[1];

      final bookMeta = bookResult['meta'];
      final loanMeta = loanResult['meta'];

      final books = bookResult['data'];
      final loans = loanResult['data'];

      totalBooks = bookMeta is Map && bookMeta['total'] != null
          ? int.tryParse(bookMeta['total'].toString()) ?? 0
          : bookResult['total'] != null
              ? int.tryParse(bookResult['total'].toString()) ?? 0
              : books is List
                  ? books.length
                  : 0;

      totalLoans = loanMeta is Map && loanMeta['total'] != null
          ? int.tryParse(loanMeta['total'].toString()) ?? 0
          : loanResult['total'] != null
              ? int.tryParse(loanResult['total'].toString()) ?? 0
              : loans is List
                  ? loans.length
                  : 0;

      if (books is List) {
        latestBooks = books
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .take(3)
            .toList();
      } else {
        latestBooks = [];
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akunmu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AuthService.logout();
    } catch (_) {
      // Sesi lokal tetap dibersihkan oleh AuthService.
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) {
      if (mounted) loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Siswa'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: isLoading ? null : loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.waving_hand_outlined,
                    color: Colors.white,
                    size: 34,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Selamat datang,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    studentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Temukan buku favoritmu dan pantau peminjaman di sini.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Ringkasan',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: loadDashboard,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 340 ? 1 : 2;

                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 1 ? 2.0 : 0.95,
                    children: [
                      StatCard(
                        title: 'Katalog Buku',
                        value: totalBooks.toString(),
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFF2563EB),
                      ),
                      StatCard(
                        title: 'Peminjaman Saya',
                        value: totalLoans.toString(),
                        icon: Icons.bookmark_border_rounded,
                        color: const Color(0xFF7C3AED),
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 24),

            const Text(
              'Menu Siswa',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(
                    Icons.library_books_outlined,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text(
                  'Katalog Buku',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Cari buku dan ajukan peminjaman.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openPage(const BookListPage()),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF3E8FF),
                  child: Icon(
                    Icons.history_rounded,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                title: const Text(
                  'Riwayat Peminjaman',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Lihat status peminjaman bukumu.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openPage(const StudentLoanPage()),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Buku Terbaru',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (!isLoading &&
                errorMessage == null &&
                latestBooks.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Belum ada buku yang tersedia.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (!isLoading && errorMessage == null)
              ...latestBooks.map(
                (book) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BookCard(
                    book: book,
                    onTap: () => openPage(const BookListPage()),
                  ),
                ),
              ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: () => openPage(const BookListPage()),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Lihat Semua Buku'),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
