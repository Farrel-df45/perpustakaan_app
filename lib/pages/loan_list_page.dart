import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/loan_service.dart';

class LoanListPage extends StatefulWidget {
  const LoanListPage({super.key});

  @override
  State<LoanListPage> createState() => _LoanListPageState();
}

class _LoanListPageState extends State<LoanListPage> {
  List<Map<String, dynamic>> loans = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedStatus = 'all';

  bool get isAdmin => AuthService.isAdmin;
  String? get token => AuthService.token;

  @override
  void initState() {
    super.initState();
    loadLoans();
  }

  Future<void> loadLoans() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await LoanService.getLoans(token: token!);
      final rawData = result['data'];

      if (rawData is List) {
        loans = rawData
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        loans = [];
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get filteredLoans {
    if (selectedStatus == 'all') return loans;

    return loans.where((loan) {
      return loan['status']?.toString() == selectedStatus;
    }).toList();
  }

  Future<void> handleAction(
    Map<String, dynamic> loan,
    String action,
  ) async {
    final id = int.tryParse(loan['id']?.toString() ?? '');

    if (id == null || token == null) {
      showMessage('Data peminjaman tidak valid.');
      return;
    }

    final actionText = switch (action) {
      'approve' => 'menyetujui pengajuan ini',
      'reject' => 'menolak pengajuan ini',
      'return' => 'memproses pengembalian buku ini',
      _ => 'memproses peminjaman ini',
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Yakin ingin $actionText?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      switch (action) {
        case 'approve':
          await LoanService.approve(
            token: token!,
            loanId: id,
          );
          break;
        case 'reject':
          await LoanService.reject(
            token: token!,
            loanId: id,
          );
          break;
        case 'return':
          await LoanService.returnBook(
            token: token!,
            loanId: id,
          );
          break;
      }

      if (!mounted) return;

      showMessage('Tindakan berhasil diproses.');
      await loadLoans();
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

  String formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'Menunggu persetujuan';
      case 'borrowed':
        return 'Sedang dipinjam';
      case 'rejected':
        return 'Ditolak';
      case 'returned':
        return 'Dikembalikan';
      default:
        return status ?? 'Tidak diketahui';
    }
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'borrowed':
        return const Color(0xFF2563EB);
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'returned':
        return const Color(0xFF16A34A);
      default:
        return Colors.grey;
    }
  }

  Widget buildActionButtons(Map<String, dynamic> loan) {
    final status = loan['status']?.toString();

    if (!isAdmin) return const SizedBox.shrink();

    if (status == 'pending') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () => handleAction(loan, 'approve'),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Setujui'),
          ),
          OutlinedButton.icon(
            onPressed: () => handleAction(loan, 'reject'),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Tolak'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      );
    }

    if (status == 'borrowed') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => handleAction(loan, 'return'),
          icon: const Icon(Icons.assignment_turned_in_outlined),
          label: const Text('Proses Pengembalian'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget buildLoanCard(Map<String, dynamic> loan) {
    final book = loan['book'] is Map
        ? Map<String, dynamic>.from(loan['book'])
        : <String, dynamic>{};

    final user = loan['user'] is Map
        ? Map<String, dynamic>.from(loan['user'])
        : <String, dynamic>{};

    final status = loan['status']?.toString();
    final color = statusColor(status);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title']?.toString() ??
                            'Buku tidak tersedia',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book['author']?.toString() ??
                            'Penulis tidak diketahui',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isAdmin) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user['name']?.toString() ??
                          'Nama siswa tidak tersedia',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel(status),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            detailLine(
              'Tanggal pinjam',
              formatDate(loan['borrowed_at']),
            ),
            detailLine(
              'Batas pengembalian',
              formatDate(loan['due_at']),
            ),
            if (loan['returned_at'] != null)
              detailLine(
                'Tanggal kembali',
                formatDate(loan['returned_at']),
              ),
            if (isAdmin) ...[
              const SizedBox(height: 16),
              buildActionButtons(loan),
            ],
          ],
        ),
      ),
    );
  }

  Widget detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 155,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peminjaman Buku'),
        actions: [
          IconButton(
            onPressed: loadLoans,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              children: [
                filterChip('all', 'Semua'),
                filterChip('pending', 'Menunggu'),
                filterChip('borrowed', 'Dipinjam'),
                filterChip('returned', 'Dikembalikan'),
                filterChip('rejected', 'Ditolak'),
              ],
            ),
          ),
          Expanded(child: buildContent()),
        ],
      ),
    );
  }

  Widget filterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedStatus == value,
        onSelected: (_) {
          setState(() => selectedStatus = value);
        },
      ),
    );
  }

  Widget buildContent() {
    if (isLoading && loans.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null && loans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: loadLoans,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final data = filteredLoans;

    if (data.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadLoans,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 12),
            Center(
              child: Text('Belum ada data peminjaman.'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadLoans,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return buildLoanCard(data[index]);
        },
      ),
    );
  }
}