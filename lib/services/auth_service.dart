import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

/// ✅ ข้อมูลผู้ใช้ / Rider ใช้ร่วมกันได้
class UserData {
  final String userId;
  final String role;
  final String phone;
  final String name;
  final num wallet;
  final String profileImage;
  final String? vehiclePlate;
  final String? vehicleImage;

  UserData({
    required this.userId,
    required this.role,
    required this.phone,
    required this.name,
    required this.wallet,
    required this.profileImage,
    this.vehiclePlate,
    this.vehicleImage,
  });

  factory UserData.fromJson(Map<String, dynamic> j) => UserData(
    userId: j['userId'] ?? '',
    role: j['role'] ?? 'user',
    phone: j['phone'] ?? '',
    name: j['name'] ?? '',
    wallet: j['wallet'] ?? 0,
    profileImage: j['profileImage'] ?? '',
    vehiclePlate: j['vehiclePlate'],
    vehicleImage: j['vehicleImage'],
  );
}

/// ✅ จัดการข้อผิดพลาด API
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// ✅ จัดการระบบ Auth ทั้งหมด
class AuthService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final _storage = const FlutterSecureStorage();

  // ------------------ Helper Function ------------------

  Future<Map<String, dynamic>> _decode(http.StreamedResponse res) async {
    final body = await res.stream.bytesToString();
    final map = body.isNotEmpty ? json.decode(body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return map as Map<String, dynamic>;
    }
    final msg = (map is Map && map['message'] is String)
        ? map['message']
        : 'Request failed (${res.statusCode})';
    throw ApiException(msg.toString(), statusCode: res.statusCode);
  }

  Future<Map<String, String>> _authHeader() async {
    final token = await _storage.read(key: 'token');
    return token == null ? {} : {'Authorization': 'Bearer $token'};
  }

  // ------------------ ตรวจสอบเบอร์โทร ------------------

  Future<Map<String, dynamic>> checkPhone(String phone) async {
    final uri = Uri.parse('$baseUrl/api/auth/check-phone/$phone');
    try {
      final res = await http.get(uri);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException('Server error (${res.statusCode})');
      }
      return json.decode(res.body) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
    } catch (e) {
      throw ApiException('เกิดข้อผิดพลาดในการตรวจสอบเบอร์: $e');
    }
  }

  // ------------------ สมัครผู้ใช้ ------------------

  Future<void> registerUser({
    required String phone,
    required String password,
    required String name,
    File? profileImage,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register-user');
    final req = http.MultipartRequest('POST', uri)
      ..fields['phone'] = phone
      ..fields['password'] = password
      ..fields['name'] = name;

    if (profileImage != null) {
      req.files.add(
        await http.MultipartFile.fromPath('profileImage', profileImage.path),
      );
    }

    final res = await req.send();
    final map = await _decode(res);
    debugPrint('✅ registerUser success: ${map['message']}');
  }

  // ------------------ สมัคร Rider ------------------

  Future<void> registerRider({
    required String phone,
    required String password,
    required String name,
    String? vehiclePlate,
    File? profileImage,
    File? vehicleImage,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register-rider');
    final req = http.MultipartRequest('POST', uri)
      ..fields['phone'] = phone
      ..fields['password'] = password
      ..fields['name'] = name;
    if (vehiclePlate != null) req.fields['vehiclePlate'] = vehiclePlate;

    if (profileImage != null) {
      req.files.add(
        await http.MultipartFile.fromPath('profileImage', profileImage.path),
      );
    }
    if (vehicleImage != null) {
      req.files.add(
        await http.MultipartFile.fromPath('vehicleImage', vehicleImage.path),
      );
    }

    final res = await req.send();
    try {
      final map = await _decode(res);
      debugPrint('✅ registerRider success: ${map['message']}');
    } on ApiException catch (e) {
      if (e.message.contains('Rider แล้ว')) {
        throw ApiException(
          'เบอร์นี้ถูกใช้งานในบัญชี Rider แล้ว',
          statusCode: e.statusCode,
        );
      } else {
        rethrow;
      }
    }
  }

  // ------------------ เข้าสู่ระบบ ------------------

  Future<UserData> login({
    required String phone,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone, 'password': password}),
      );

      // ✅ แปลงข้อมูลตอบกลับ
      final Map<String, dynamic> map = json.decode(res.body);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(
          map['message']?.toString() ?? 'เข้าสู่ระบบล้มเหลว',
          statusCode: res.statusCode,
        );
      }

      // ✅ ตรวจสอบโครงสร้างข้อมูล
      final token = map['data']?['token'] as String?;
      final user = map['data']?['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        throw ApiException('โครงสร้างข้อมูลไม่ถูกต้องจากเซิร์ฟเวอร์');
      }

      // ✅ เก็บข้อมูลใน Secure Storage
      await _storage.write(key: 'token', value: token);
      await _storage.write(key: 'userId', value: user['userId'] ?? '');
      await _storage.write(key: 'role', value: user['role'] ?? 'user');
      await _storage.write(key: 'phone', value: user['phone'] ?? '');

      debugPrint('🔐 JWT token saved (${user['role']})');

      return UserData.fromJson(user);
    } on SocketException {
      throw ApiException(
        'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ โปรดตรวจสอบอินเทอร์เน็ต',
      );
    } on FormatException {
      throw ApiException('ข้อมูลตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('เกิดข้อผิดพลาดระหว่างเข้าสู่ระบบ: $e');
    }
  }

  // ------------------ ดึงโปรไฟล์ตัวเอง ------------------

  Future<UserData> getMe() async {
    final uri = Uri.parse('$baseUrl/api/users/me');
    final res = await http.get(uri, headers: await _authHeader());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final m = json.decode(res.body);
      throw ApiException(
        m['message']?.toString() ?? 'Fetch failed',
        statusCode: res.statusCode,
      );
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    return UserData.fromJson(map['data'] as Map<String, dynamic>);
  }

  // ------------------ อัปเดตโปรไฟล์ ------------------

  Future<UserData> updateMe({
    String? name,
    File? profileImage,
    String? vehiclePlate,
    File? vehicleImage,
  }) async {
    final uri = Uri.parse('$baseUrl/api/users/me');
    final req = http.MultipartRequest('PUT', uri);
    req.headers.addAll(await _authHeader());

    if (name != null) req.fields['name'] = name;
    if (vehiclePlate != null) req.fields['vehiclePlate'] = vehiclePlate;

    if (profileImage != null) {
      req.files.add(
        await http.MultipartFile.fromPath('profileImage', profileImage.path),
      );
    }
    if (vehicleImage != null) {
      req.files.add(
        await http.MultipartFile.fromPath('vehicleImage', vehicleImage.path),
      );
    }

    final res = await req.send();
    final map = await _decode(res);
    return UserData.fromJson(map['data'] as Map<String, dynamic>);
  }

  // ------------------ ตรวจสอบสถานะการเข้าสู่ระบบ ------------------

  Future<String?> getCurrentRole() async {
    return await _storage.read(key: 'role');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null && token.isNotEmpty;
  }

  // ------------------ ออกจากระบบ ------------------

  Future<void> logout() async {
    await _storage.deleteAll();
    debugPrint('🚪 Logged out');
  }
}
