import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class BookService {
  static Future<Map<String, dynamic>> getBooks({
    String? search,
    String? token,
  }) async {
    final query = search != null && search.trim().isNotEmpty
        ? '?search=${Uri.encodeQueryComponent(search.trim())}'
        : '';

    final result = await ApiService.get(
      '/books$query',
      token: token,
    );

    if (result is Map<String, dynamic>) {
      return result;
    }

    throw Exception('Format daftar buku tidak valid.');
  }

  static Future<Map<String, dynamic>> getBook(
    int id, {
    String? token,
  }) async {
    final result = await ApiService.get(
      '/books/$id',
      token: token,
    );

    if (result is Map<String, dynamic>) {
      return result;
    }

    throw Exception('Format detail buku tidak valid.');
  }

  static Future<dynamic> createBook({
    required String token,
    required String title,
    required String author,
    String? publisher,
    String? category,
    required int stockTotal,
    String? shelf,
    String? imagePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/books'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields.addAll({
      'title': title,
      'author': author,
      'stock_total': stockTotal.toString(),
      if (publisher != null && publisher.isNotEmpty)
        'publisher': publisher,
      if (category != null && category.isNotEmpty)
        'category': category,
      if (shelf != null && shelf.isNotEmpty)
        'shelf': shelf,
    });

    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'cover_image',
          imagePath,
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return ApiService.decodeResponse(response);
  }

  static Future<dynamic> updateBook({
    required String token,
    required int id,
    required String title,
    required String author,
    String? publisher,
    String? category,
    required int stockTotal,
    String? shelf,
    String? imagePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/books/$id'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields.addAll({
      '_method': 'PUT',
      'title': title,
      'author': author,
      'stock_total': stockTotal.toString(),
      if (publisher != null) 'publisher': publisher,
      if (category != null) 'category': category,
      if (shelf != null) 'shelf': shelf,
    });

    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'cover_image',
          imagePath,
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return ApiService.decodeResponse(response);
  }

  static Future<void> deleteBook({
    required String token,
    required int id,
  }) async {
    await ApiService.delete(
      '/books/$id',
      token: token,
    );
  }
}