import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/loan_service.dart';

class LoanDetailPage extends StatefulWidget {
  final Map<String, dynamic> loan;

  const LoanDetailPage({
    super.key,
    required this.loan,
  });

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  late Map<String, dynamic> loan;
  bool isProcessing = false;

  bool get isAdmin => AuthService.isAdmin;

  @override
  void initState() {
    super.initState();
    loan = Map<String, dynamic>.from(widget.loan);
  }

  String get status {
    return loan['status']?.toString().toLowerCase() ?? 'pending';
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Persetujuan';
      case 'borrowed':
        return 'Sedang Dipinjam';
      case 'returned':
        return 'Sudah Dikembalikan';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'borrowed':
        return const Color(0xFF2563EB);
      case 'returned':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      return value.toString();
    }

    final date = parsed.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }

  Future<void> performAction(String action) async {
    final token = AuthService.token;
    final loanId = int.tryParse(loan['id']?.toString() ?? '');

    if (token == null || loanId == null) {
      showMessage('Data peminjaman atau sesi login tidak valid.');
      return;
    }

    String confirmation;
    switch (action) {
      case 'approve':
        confirmation = 'Setujui peminjaman buku ini?';
        break;
      case 'reject':
        confirmation = 'Tolak pengajuan peminjaman ini?';
        break;
      default:
        confirmation = 'Konfirmasi bahwa buku sudah dikembalikan?';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(confirmation),
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

    if (confirmed != true || !mounted) return;

    setState(() => isProcessing = true);

    try {
      switch (action) {
        case 'approve':
          await LoanService.approve(token: token, loanId: loanId);
          break;
        case 'reject':
          await LoanService.reject(token: token, loanId: loanId);
          break;
        case 'return':
          await LoanService.returnBook(token: token, loanId: loanId);
          break;
      }

      if (!mounted) return;

      setState(() {
        loan['status'] = action == 'approve'
            ? 'borrowed'
            : action == 'reject'
                ? 'rejected'
                : 'returned';
      });

      showMessage('Status peminjaman berhasil diperbarui.');

      Navigator.pop(context, true);
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget detailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = loan['book'] is Map
        ? Map<String, dynamic>.from(loan['book'])
        : <String, dynamic>{};

    final user = loan['user'] is Map
        ? Map<String, dynamic>.from(loan['user'])
        : <String, dynamic>{};

    final title = book['title']?.toString() ?? 'Buku tidak diketahui';
    final author = book['author']?.toString() ?? '-';
    final studentName = user['name']?.toString() ?? '-';
    final studentEmail = user['email']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Peminjaman'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Icon(
                  Icons.menu_book_rounded,
                  size: 42,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Penulis: $author',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Peminjaman',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  detailRow(
                    'ID Peminjaman',
                    loan['id']?.toString() ?? '-',
                    Icons.confirmation_number_outlined,
                  ),
                  detailRow(
                    'Tanggal Pengajuan',
                    formatDate(loan['created_at']),
                    Icons.calendar_today_outlined,
                  ),
                  detailRow(
                    'Tanggal Peminjaman',
                    formatDate(loan['borrowed_at'] ?? loan['loan_date']),
                    Icons.event_available_outlined,
                  ),
                  detailRow(
                    'Tanggal Pengembalian',
                    formatDate(loan['returned_at'] ?? loan['return_date']),
                    Icons.event_busy_outlined,
                  ),
                ],
              ),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Siswa',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    detailRow(
                      'Nama Siswa',
                      studentName,
                      Icons.person_outline,
                    ),
                    detailRow(
                      'Email',
                      studentEmail,
                      Icons.email_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (isAdmin && status == 'pending') ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isProcessing
                    ? null
                    : () => performAction('approve'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Setujui Peminjaman'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () => performAction('reject'),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Tolak Peminjaman'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ),
          ],
          if (isAdmin && status == 'borrowed') ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isProcessing
                    ? null
                    : () => performAction('return'),
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: const Text('Konfirmasi Pengembalian'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ),
          ],
          if (isProcessing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}