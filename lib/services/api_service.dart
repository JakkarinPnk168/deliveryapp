import 'dart:convert';
import 'dart:io';
import 'package:deliveryapp/models/order_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user_model.dart';
import '../models/address_model.dart';
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
          'profileImage',
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
      final List data = body['data'] ?? [];
      return data.map((e) => AddressModel.fromJson(e)).toList();
    } else {
      throw HttpException(
        'Fetch addresses failed: ${res.statusCode} ${res.body}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 4. เพิ่มที่อยู่ใหม่ (POST)
  // ---------------------------------------------------------------------------
  Future<AddressModel> createAddress(String token, AddressModel address) async {
    final url = Uri.parse('$baseUrl/api/users/me/addresses');

    // ✅ ใช้ address.toJson() เพื่อส่งข้อมูลครบทุกฟิลด์
    final body = jsonEncode(address.toJson());

    final res = await _client.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    // ✅ ตรวจสอบสถานะการตอบกลับ
    if (res.statusCode == 201 || res.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(res.body);
      final data = json['data'] ?? json;
      return AddressModel.fromJson(data);
    }

    throw HttpException('Create address failed: ${res.statusCode} ${res.body}');
  }

  // ---------------------------------------------------------------------------
  // 🔹 5. ดึงข้อมูลที่อยู่เดี่ยว (GET /:id)
  // ---------------------------------------------------------------------------
  Future<AddressModel> getAddressById(String token, String addressId) async {
    final url = Uri.parse('$baseUrl/api/users/me/addresses/$addressId');
    final res = await _client.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    print("🟢 Response body = ${res.body}");
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final data = body['data'] ?? body;
      return AddressModel.fromJson(data);
    } else {
      throw HttpException(
        'Fetch address failed: ${res.statusCode} ${res.body}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 6. แก้ไขที่อยู่ (PUT)
  // ---------------------------------------------------------------------------
  Future<AddressModel> updateAddress(
    String token,
    String addressId, {
    String? label,
    String? recipientName,
    String? phone,
    String? address_detail,
    String? subDistrict,
    String? district,
    String? province,
    String? postalCode,
    double? gps_latitude,
    double? gps_longitude,
    bool? isDefault,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/me/addresses/$addressId');

    final Map<String, dynamic> payload = {};
    if (label != null) payload['label'] = label;
    if (recipientName != null) payload['recipientName'] = recipientName;
    if (phone != null) payload['phone'] = phone;
    if (address_detail != null) payload['address_detail'] = address_detail;
    if (subDistrict != null) payload['subDistrict'] = subDistrict;
    if (district != null) payload['district'] = district;
    if (province != null) payload['province'] = province;
    if (postalCode != null) payload['postalCode'] = postalCode;
    if (gps_latitude != null) payload['gps_latitude'] = gps_latitude;
    if (gps_longitude != null) payload['gps_longitude'] = gps_longitude;
    if (isDefault != null) payload['isDefault'] = isDefault;

    final res = await _client.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(res.body);
      final data = json['data'] ?? json;
      return AddressModel.fromJson(data);
    }

    throw HttpException('Update address failed: ${res.statusCode} ${res.body}');
  }

  // ---------------------------------------------------------------------------
  // 🔹 7. ลบที่อยู่ (DELETE)
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
  // 🔹 8. ตั้งค่าที่อยู่เริ่มต้น (optional ฟีเจอร์เสริม)
  // ---------------------------------------------------------------------------
  Future<AddressModel> setDefaultAddress(String token, String addressId) async {
    final url = Uri.parse('$baseUrl/api/users/me/addresses/$addressId');
    final res = await _client.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'isDefault': true}),
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(res.body);
      final data = json['data'] ?? json;
      return AddressModel.fromJson(data);
    }
    throw HttpException('Set default failed: ${res.statusCode} ${res.body}');
  }

  // ---------------------------------------------------------------------------
  // 🔹 Utility: ตรวจสอบ token หรือ network error
  // ---------------------------------------------------------------------------
  static bool isUnauthorizedError(Object e) {
    return e is HttpException && e.message.contains('401');
  }

  // ---------------------------------------------------------------------------
  // 🔹 รับงาน
  // ---------------------------------------------------------------------------
  Future<void> acceptOrder(String token, String orderId) async {
    final url = Uri.parse('$baseUrl/api/orders/$orderId/accept');
    final res = await _client.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw HttpException(
        'Failed to accept order: ${res.statusCode} ${res.body}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 7. Rider orders: ดึงรายการงาน
  // ---------------------------------------------------------------------------
  Future<List<Order>> getRiderOrders(String token) async {
    final url = Uri.parse('$baseUrl/api/orders/rider');
    final res = await _client.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List data = body['data'] ?? [];
      return data.map((e) => Order.fromJson(e)).toList();
    }

    throw HttpException(
      'Failed to fetch orders: ${res.statusCode} ${res.body}',
    );
  }
}
