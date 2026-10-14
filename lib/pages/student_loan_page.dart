import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/loan_service.dart';

class StudentLoanPage extends StatefulWidget {
  const StudentLoanPage({super.key});

  @override
  State<StudentLoanPage> createState() => _StudentLoanPageState();
}

class _StudentLoanPageState extends State<StudentLoanPage> {
  List<Map<String, dynamic>> loans = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedStatus = 'all';

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
      final token = AuthService.token;

      if (token == null) {
        throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
      }

      final result = await LoanService.getLoans(token: token);
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

    return loans
        .where((loan) => loan['status']?.toString() == selectedStatus)
        .toList();
  }

  String statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'Menunggu persetujuan';
      case 'borrowed':
        return 'Sedang dipinjam';
      case 'rejected':
        return 'Pengajuan ditolak';
      case 'returned':
        return 'Sudah dikembalikan';
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

  Widget detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
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

  Widget buildLoanCard(Map<String, dynamic> loan) {
    final book = loan['book'] is Map
        ? Map<String, dynamic>.from(loan['book'])
        : <String, dynamic>{};

    final status = loan['status']?.toString();
    final color = statusColor(status);
    final coverUrl = book['cover_url']?.toString();

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 66,
                    height: 90,
                    child: coverUrl != null && coverUrl.isNotEmpty
                        ? Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _bookPlaceholder(),
                          )
                        : _bookPlaceholder(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title']?.toString() ?? 'Buku',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        book['author']?.toString() ?? 'Penulis tidak diketahui',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                ),
              ],
            ),
            const Divider(height: 28),
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
                'Tanggal dikembalikan',
                formatDate(loan['returned_at']),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bookPlaceholder() {
    return Container(
      color: const Color(0xFFEFF6FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        size: 30,
        color: Color(0xFF2563EB),
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
      return const Center(child: CircularProgressIndicator());
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
            SizedBox(height: 110),
            Icon(
              Icons.receipt_long_outlined,
              size: 52,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 12),
            Center(
              child: Text('Belum ada riwayat peminjaman.'),
            ),
            SizedBox(height: 6),
            Center(
              child: Text(
                'Ajukan peminjaman melalui katalog buku.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Peminjaman'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: loadLoans,
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
}