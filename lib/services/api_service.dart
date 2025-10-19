import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user_model.dart';
import '../models/address_model.dart'; // ✅ ต้องมี import นี้
import '../config/app_config.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
      _client = client ?? http.Client();

  // ---------------------------------------------------------------------------
  // 🔹 1. ดึงข้อมูลโปรไฟล์ผู้ใช้
  // ---------------------------------------------------------------------------
  Future<UserModel> getMe(String token) async {
    final url = Uri.parse('$baseUrl/api/users/me');
    final res = await _client.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(res.body);
      final data = body['data'] ?? body;
      return UserModel.fromJson(data);
    }

    throw HttpException('Failed to load user: ${res.statusCode} ${res.body}');
  }

  // ---------------------------------------------------------------------------
  // 🔹 2. อัปเดตข้อมูลโปรไฟล์ (ชื่อ, เบอร์โทร, รูปโปรไฟล์)
  // ---------------------------------------------------------------------------
  Future<UserModel> updateProfile(
    String token, {
    String? name,
    String? phone,
    File? imageFile,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/me');

    final request = http.MultipartRequest('PUT', url)
      ..headers['Authorization'] = 'Bearer $token';

    if (name != null) request.fields['name'] = name;
    if (phone != null) request.fields['phone'] = phone;

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profileImage', // ฟิลด์ใน backend
          imageFile.path,
          contentType: MediaType('image', _guessExt(imageFile.path)),
        ),
      );
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(res.body);
      final data = body['data'] ?? body;
      return UserModel.fromJson(data);
    }
    throw HttpException('Failed to update: ${res.statusCode} ${res.body}');
  }

  // ---------------------------------------------------------------------------
  // 🔹 Helper: ตรวจนามสกุลไฟล์
  // ---------------------------------------------------------------------------
  String _guessExt(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    if (lower.endsWith('.gif')) return 'gif';
    return 'jpeg';
  }

  // ---------------------------------------------------------------------------
  // 🔹 3. ดึงรายการที่อยู่ทั้งหมด
  // ---------------------------------------------------------------------------
  Future<List<AddressModel>> getAddresses(String token) async {
    final url = Uri.parse('$baseUrl/api/users/me/addresses');
    final res = await _client.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List data = body['data'] ?? body;
      return data.map((e) => AddressModel.fromJson(e)).toList();
    }

    throw HttpException(
      'Fetch addresses failed: ${res.statusCode} ${res.body}',
    );
  }

  // ---------------------------------------------------------------------------
  // 🔹 4. เพิ่มที่อยู่ใหม่ (POST → Firestore)
  // ---------------------------------------------------------------------------
  Future<AddressModel> createAddress(String token, AddressModel address) async {
    final url = Uri.parse('$baseUrl/api/users/me/addresses');

    final res = await _client.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "address_detail": address.addressLine,
        "gps_latitude": address.lat,
        "gps_longitude": address.lng,
        "isDefault": address.isDefault,
      }),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(res.body);
      final data = body['data'] ?? body;
      return AddressModel.fromJson(data);
    }

    throw HttpException('Create address failed: ${res.statusCode} ${res.body}');
  }

  // ---------------------------------------------------------------------------
  // 🔹 5. แก้ไขที่อยู่
  // ---------------------------------------------------------------------------
  Future<AddressModel> updateAddress(
    String token,
    String addressId, {
    String? address_detail,
    double? gps_latitude,
    double? gps_longitude,
    bool? isDefault,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/me/addresses/$addressId');
    final body = {
      if (address_detail != null) 'address_detail': address_detail,
      if (gps_latitude != null) 'gps_latitude': gps_latitude,
      if (gps_longitude != null) 'gps_longitude': gps_longitude,
      if (isDefault != null) 'isDefault': isDefault,
    };

    final res = await _client.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(res.body);
      final data = body['data'] ?? body;
      return AddressModel.fromJson(data);
    }

    throw HttpException('Update address failed: ${res.statusCode} ${res.body}');
  }

  // ---------------------------------------------------------------------------
  // 🔹 6. ลบที่อยู่
  // ---------------------------------------------------------------------------
  Future<void> deleteAddress(String token, String addressId) async {
    final url = Uri.parse('$baseUrl/api/users/me/addresses/$addressId');
    final res = await _client.delete(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw HttpException('Delete failed: ${res.statusCode} ${res.body}');
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 Utility: ตรวจสอบ token หรือ network error
  // ---------------------------------------------------------------------------
  static bool isUnauthorizedError(Object e) {
    return e is HttpException && e.message.contains('401');
  }
}
