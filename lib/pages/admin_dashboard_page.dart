import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/book_service.dart';
import '../services/loan_service.dart';
import '../widgets/stat_card.dart';
import 'book_list_page.dart';
import 'loan_list_page.dart';
import 'login_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool isLoading = true;
  String? errorMessage;

  int totalBooks = 0;
  int totalLoans = 0;
  int pendingLoans = 0;
  int activeLoans = 0;

  String get adminName =>
      AuthService.user?['name']?.toString() ?? 'Admin';

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final token = AuthService.token;

    if (token == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Sesi login tidak ditemukan.';
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

      final books = bookResult['data'];
      final loans = loanResult['data'];

      final bookMeta = bookResult['meta'];
      final loanMeta = loanResult['meta'];

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

      pendingLoans = 0;
      activeLoans = 0;

      if (loans is List) {
        for (final item in loans) {
          if (item is! Map) continue;

          final status = item['status']?.toString().toLowerCase();

          if (status == 'pending') {
            pendingLoans++;
          } else if (status == 'borrowed') {
            activeLoans++;
          }
        }
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
        content: const Text('Yakin ingin keluar dari akun admin?'),
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
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (_) => false,
    );
  }

  Widget menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: loadDashboard,
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
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Colors.white,
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Selamat datang,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    adminName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kelola katalog buku dan peminjaman perpustakaan.',
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
              'Ringkasan Perpustakaan',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
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
                        title: 'Total Buku',
                        value: totalBooks.toString(),
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFF2563EB),
                      ),
                      StatCard(
                        title: 'Total Peminjaman',
                        value: totalLoans.toString(),
                        icon: Icons.library_books_outlined,
                        color: const Color(0xFF7C3AED),
                      ),
                      StatCard(
                        title: 'Menunggu Persetujuan',
                        value: pendingLoans.toString(),
                        icon: Icons.pending_actions_outlined,
                        color: const Color(0xFFD97706),
                      ),
                      StatCard(
                        title: 'Sedang Dipinjam',
                        value: activeLoans.toString(),
                        icon: Icons.bookmark_added_outlined,
                        color: const Color(0xFF16A34A),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
            const Text(
              'Menu Pengelolaan',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            menuCard(
              icon: Icons.menu_book_rounded,
              title: 'Kelola Buku',
              subtitle: 'Tambah, edit, cari, dan hapus buku.',
              color: const Color(0xFF2563EB),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookListPage(),
                  ),
                ).then((_) {
                  if (mounted) loadDashboard();
                });
              },
            ),
            const SizedBox(height: 10),
            menuCard(
              icon: Icons.assignment_outlined,
              title: 'Kelola Peminjaman',
              subtitle: 'Periksa pengajuan dan proses pengembalian.',
              color: const Color(0xFF7C3AED),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoanListPage(),
                  ),
                ).then((_) {
                  if (mounted) loadDashboard();
                });
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}