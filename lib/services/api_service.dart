import 'dart:convert';
import 'dart:io';
<<<<<<< HEAD
import 'dart:typed_data';
=======
>>>>>>> 6916f3ce840ffa46de1a4cf3f0f21127ced845df
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user_model.dart';
import '../models/address_model.dart'; // ✅ ต้องมี import นี้
<<<<<<< HEAD
import '../models/order_model.dart'; // ✅ สำหรับ Rider orders
=======
>>>>>>> 6916f3ce840ffa46de1a4cf3f0f21127ced845df
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
<<<<<<< HEAD
          'profileImage',
=======
          'profileImage', // ฟิลด์ใน backend
>>>>>>> 6916f3ce840ffa46de1a4cf3f0f21127ced845df
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
<<<<<<< HEAD
  // 🔹 4. เพิ่มที่อยู่ใหม่
=======
  // 🔹 4. เพิ่มที่อยู่ใหม่ (POST → Firestore)
>>>>>>> 6916f3ce840ffa46de1a4cf3f0f21127ced845df
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
<<<<<<< HEAD
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
  // 🔹 อัปเดตสถานะ + อัปโหลดรูป
  // ---------------------------------------------------------------------------
  Future<void> updateOrderStatus(
    String token,
    String orderId,
    int status, {
    Uint8List? image,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/orders/$orderId/status'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['status'] = status.toString();

    if (image != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          image,
          filename: 'status$image.jpg',
        ),
      );
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw HttpException(
        'Failed to update order: ${res.statusCode} ${res.body}',
      );
    }
  }

  // ---------------------------------------------------------------------------
=======
>>>>>>> 6916f3ce840ffa46de1a4cf3f0f21127ced845df
  // 🔹 Utility: ตรวจสอบ token หรือ network error
  // ---------------------------------------------------------------------------
  static bool isUnauthorizedError(Object e) {
    return e is HttpException && e.message.contains('401');
  }
}
