import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
static const String baseUrl = 'http://192.168.1.7:8000/api';

static Map<String, String> headers({String? token}) {
return {
'Accept': 'application/json',
'Content-Type': 'application/json',
if (token != null && token.isNotEmpty)
'Authorization': 'Bearer $token',
};
}

static dynamic decode(http.Response response) {
if (response.body.isEmpty) {
return {};
}

try {
  return jsonDecode(response.body);
} catch (_) {
  throw Exception('Respons server bukan JSON yang valid.');
}

}

static dynamic decodeResponse(http.Response response) {
return _handleResponse(response);
}

static Future<dynamic> get(
String path, {
String? token,
}) async {
final response = await http.get(
Uri.parse('$baseUrl$path'),
headers: headers(token: token),
);

return _handleResponse(response);

}

static Future<dynamic> post(
String path, {
String? token,
Map<String, dynamic>? body,
}) async {
final response = await http.post(
Uri.parse('$baseUrl$path'),
headers: headers(token: token),
body: jsonEncode(body ?? {}),
);

return _handleResponse(response);

}

static Future<dynamic> put(
String path, {
String? token,
Map<String, dynamic>? body,
}) async {
final response = await http.put(
Uri.parse('$baseUrl$path'),
headers: headers(token: token),
body: jsonEncode(body ?? {}),
);

return _handleResponse(response);

}

static Future<dynamic> delete(
String path, {
String? token,
}) async {
final response = await http.delete(
Uri.parse('$baseUrl$path'),
headers: headers(token: token),
);

return _handleResponse(response);

}

static dynamic _handleResponse(http.Response response) {
final result = decode(response);

if (response.statusCode < 200 ||
    response.statusCode >= 300) {
  final message = result is Map
      ? result['message']?.toString() ??
          'Permintaan gagal (${response.statusCode}).'
      : 'Permintaan gagal (${response.statusCode}).';

  throw Exception(message);
}

return result;

}
}
