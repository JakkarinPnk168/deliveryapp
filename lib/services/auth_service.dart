import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

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

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class AuthService {
  final String baseUrl = AppConfig.apiBaseUrl;

  final _storage = const FlutterSecureStorage();

<<<<<<< HEAD
  Future<String?> get token async {
    return await _storage.read(key: 'token');
  }

  get currentUser => null;

=======
>>>>>>> 6916f3ce840ffa46de1a4cf3f0f21127ced845df
  Future<Map<String, dynamic>> _decode(http.StreamedResponse res) async {
    final body = await res.stream.bytesToString();
    final map = body.isNotEmpty ? json.decode(body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300)
      return map as Map<String, dynamic>;
    final msg = (map is Map && map['message'] is String)
        ? map['message']
        : 'Request failed (${res.statusCode})';
    throw ApiException(msg.toString(), statusCode: res.statusCode);
  }

  Future<Map<String, String>> _authHeader() async {
    final token = await _storage.read(key: 'token');
    return token == null ? {} : {'Authorization': 'Bearer $token'};
  }

  // ✅ สมัคร USER (รองรับโปรไฟล์รูป)
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
    await _decode(res);
    debugPrint('✅ registerUser success');
  }

  // ✅ สมัคร RIDER (รูปโปรไฟล์ + รูปรถ + ทะเบียนรถ)
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
    await _decode(res);
    debugPrint('✅ registerRider success');
  }

  // ✅ Login (JSON)
  Future<UserData> login({
    required String phone,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phone': phone, 'password': password}),
    );
    final map = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        map['message']?.toString() ?? 'Login failed',
        statusCode: res.statusCode,
      );
    }
    final token = map['data']?['token'] as String?;
    final user = map['data']?['user'] as Map<String, dynamic>?;
    if (token == null || user == null)
      throw ApiException('โครงสร้างข้อมูลไม่ถูกต้องจากเซิร์ฟเวอร์');
    await _storage.write(key: 'token', value: token);
    debugPrint('🔐 JWT saved');
    return UserData.fromJson(user);
  }

  // ✅ ดึงโปรไฟล์ตัวเอง (JSON)
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

  // ✅ อัปเดตโปรไฟล์: name / profileImage / (ถ้า rider: vehiclePlate, vehicleImage)
  Future<UserData> updateMe({
    String? name,
    File? profileImage,
    String? vehiclePlate,
    File? vehicleImage,
  }) async {
    final uri = Uri.parse('$baseUrl/api/users/me');
    final req = http.MultipartRequest('PUT', uri);
    final auth = await _authHeader();
    req.headers.addAll(auth);
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

  Future<void> logout() async {
    await _storage.delete(key: 'token');
  }
}
