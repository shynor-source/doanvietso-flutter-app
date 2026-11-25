import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client gọi API backend FastAPI (Vòng 2).
///
/// - Trên **emulator Android**: dùng 10.0.2.2 (alias localhost của máy host).
/// - Trên **máy thật**: đổi thành IP LAN của máy chạy backend, ví dụ `http://192.168.1.10:8000`
///   (chạy lệnh: `flutter run --dart-define=API_BASE=http://192.168.1.10:8000`).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:8000',
);

class ApiClient {
  String? token;
  http.Client _c = http.Client();

  static const Duration _timeout = Duration(seconds: 10);

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('$kApiBaseUrl$path').replace(queryParameters: q);

  Map<String, String> get _h => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  bool get hasToken => token != null;

  void setAuth(String? newToken) {
    token = newToken;
  }

  dynamic _decode(http.Response r) {
    final body = jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 400) {
      final msg = body is Map && body['detail'] != null ? body['detail'].toString() : 'Lỗi máy chủ (${r.statusCode})';
      throw ApiException(msg, r.statusCode);
    }
    return body;
  }

  Future<dynamic> get(String path, [Map<String, String>? q]) async {
    final r = await _c.get(_u(path, q), headers: _h).timeout(_timeout);
    return _decode(r);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body, Map<String, String>? q, Duration? timeout]) async {
    final r = await _c.post(_u(path, q), headers: _h, body: jsonEncode(body ?? {})).timeout(timeout ?? _timeout);
    return _decode(r);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final r = await _c.patch(_u(path), headers: _h, body: jsonEncode(body)).timeout(_timeout);
    return _decode(r);
  }

  Future<dynamic> delete(String path) async {
    final r = await _c.delete(_u(path), headers: _h).timeout(_timeout);
    return _decode(r);
  }

  /// Đăng nhập: phone + OTP
  Future<Map<String, dynamic>> requestOtp(String phone) async =>
      await post('/auth/otp', {'phone': phone});

  Future<Map<String, dynamic>> login(String phone, String otp) async {
    final data = await post('/auth/login', {'phone': phone, 'otp': otp});
    token = data['access_token'] as String?;
    return data;
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}
