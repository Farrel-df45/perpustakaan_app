import 'api_service.dart';

class LoanService {
  static Future<Map<String, dynamic>> getLoans({
    required String token,
  }) async {
    final result = await ApiService.get(
      '/loans',
      token: token,
    );

    if (result is Map<String, dynamic>) {
      return result;
    }

    throw Exception('Format data peminjaman tidak valid.');
  }

  static Future<dynamic> requestLoan({
    required String token,
    required int bookId,
  }) async {
    return ApiService.post(
      '/loans',
      token: token,
      body: {'book_id': bookId},
    );
  }

  static Future<dynamic> approve({
    required String token,
    required int loanId,
  }) async {
    return ApiService.post(
      '/loans/$loanId/approve',
      token: token,
    );
  }

  static Future<dynamic> reject({
    required String token,
    required int loanId,
  }) async {
    return ApiService.post(
      '/loans/$loanId/reject',
      token: token,
    );
  }

  static Future<dynamic> returnBook({
    required String token,
    required int loanId,
  }) async {
    return ApiService.post(
      '/loans/$loanId/return',
      token: token,
    );
  }
}