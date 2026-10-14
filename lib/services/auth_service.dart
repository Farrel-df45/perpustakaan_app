import 'api_service.dart';

class AuthService {
  static String? token;
  static Map<String, dynamic>? user;

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final result = await ApiService.post(
      '/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    if (result is! Map ||
        result['token'] == null ||
        result['user'] is! Map) {
      throw Exception('Data login dari server tidak lengkap.');
    }

    token = result['token'].toString();
    user = Map<String, dynamic>.from(result['user']);

    return user!;
  }

  static Future<Map<String, dynamic>> me() async {
    if (token == null) {
      throw Exception('Token login tidak ditemukan.');
    }

    final result = await ApiService.get(
      '/me',
      token: token,
    );

    final userData = result is Map && result['user'] is Map
        ? result['user']
        : result;

    if (userData is! Map) {
      throw Exception('Data pengguna tidak valid.');
    }

    user = Map<String, dynamic>.from(userData);
    return user!;
  }

  static Future<void> logout() async {
    try {
      if (token != null) {
        await ApiService.post(
          '/logout',
          token: token,
        );
      }
    } finally {
      token = null;
      user = null;
    }
  }

  static bool get isLoggedIn => token != null;

  static bool get isAdmin => user?['role'] == 'admin';
}