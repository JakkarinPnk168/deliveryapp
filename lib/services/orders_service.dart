import 'dart:convert';
import 'dart:io';
import 'package:deliveryapp/models/order_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import 'dart:typed_data';

/// ------------------------------------------------------------
/// 🚚 OrdersService (ฝั่ง USER / SENDER)
/// รองรับการสร้างพัสดุ / ดูพัสดุที่ส่ง / ดูพัสดุที่ได้รับ /
/// อัปโหลดหลักฐาน / ค้นหาผู้รับด้วยเบอร์โทร / ดูรายละเอียดพัสดุ
/// ------------------------------------------------------------
class OrdersService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final _storage = const FlutterSecureStorage();
  final String token;

  OrdersService(this.token);

  // ✅ ดึง Header ที่มี JWT Token
  Future<Map<String, String>> _authHeader() async {
    final token = await _storage.read(key: 'token');
    return token == null
        ? {'Content-Type': 'application/json'}
        : {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          };
  }

  // ✅ 1. ค้นหาผู้รับจากเบอร์โทร
  Future<Map<String, dynamic>?> searchReceiver(String phone) async {
    final uri = Uri.parse('$baseUrl/api/users/search?phone=$phone');
    final res = await http.get(uri, headers: await _authHeader());
    final map = json.decode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 200 &&
        res.statusCode < 300 &&
        map['success'] == true) {
      return map['data'];
    } else {
      throw Exception(map['message'] ?? 'ค้นหาผู้รับไม่สำเร็จ');
    }
  }

  // ✅ 2. สร้างออเดอร์ใหม่ (Shipment เดียว หลายสินค้า)
  Future<Map<String, dynamic>> createOrder({
    required String senderId,
    required String receiverId,
    required Map<String, dynamic> receiverAddress,
    required List<Map<String, dynamic>> items,
    List<File>? images,
  }) async {
    final uri = Uri.parse('$baseUrl/api/parcels');
    final req = http.MultipartRequest('POST', uri);

    req.fields['senderId'] = senderId;
    req.fields['receiverId'] = receiverId;
    req.fields['receiverAddress'] = json.encode(receiverAddress);
    req.fields['items'] = json.encode(items);

    // ✅ แนบรูปสินค้า
    if (images != null && images.isNotEmpty) {
      for (final img in images) {
        req.files.add(await http.MultipartFile.fromPath('images', img.path));
      }
    }

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    final map = json.decode(body);

    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      return map;
    } else {
      throw Exception(map['message'] ?? 'สร้างพัสดุไม่สำเร็จ');
    }
  }

  // ✅ 3. ดึงพัสดุทั้งหมดที่ฉันส่ง
  Future<List<Map<String, dynamic>>> getSenderParcels(String senderId) async {
    final uri = Uri.parse('$baseUrl/api/parcels/sender/$senderId');
    final res = await http.get(uri, headers: await _authHeader());
    final map = json.decode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final List list = map['data'] ?? [];
      return list.cast<Map<String, dynamic>>();
    } else {
      throw Exception(map['message'] ?? 'โหลดข้อมูลพัสดุผู้ส่งไม่สำเร็จ');
    }
  }

  // ✅ 4. ดึงพัสดุที่ฉันเป็นผู้รับ
  Future<List<Map<String, dynamic>>> getReceiverParcels(
    String receiverId,
  ) async {
    final uri = Uri.parse('$baseUrl/api/parcels/receiver/$receiverId');
    final res = await http.get(uri, headers: await _authHeader());
    final map = json.decode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final List list = map['data'] ?? [];
      return list.cast<Map<String, dynamic>>();
    } else {
      throw Exception(map['message'] ?? 'โหลดข้อมูลพัสดุผู้รับไม่สำเร็จ');
    }
  }

  // ✅ 5. อัปโหลดรูปหลักฐานการส่งสินค้า
  Future<Map<String, dynamic>> uploadProof(String orderId, File image) async {
    final uri = Uri.parse('$baseUrl/api/orders/$orderId/proof');
    final req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    final map = json.decode(body);

    if (streamed.statusCode >= 200 &&
        streamed.statusCode < 300 &&
        map['success'] == true) {
      return map['data'] ?? {};
    } else {
      throw Exception(map['message'] ?? 'อัปโหลดหลักฐานไม่สำเร็จ');
    }
  }

  // ✅ 6. ดึงรายละเอียดพัสดุ (ใช้ในหน้า ParcelDetailPage)
  Future<Map<String, dynamic>> getParcelDetail(String orderId) async {
    final uri = Uri.parse('$baseUrl/api/parcels/$orderId');
    final res = await http.get(uri, headers: await _authHeader());
    final map = json.decode(res.body);

    if (res.statusCode >= 200 &&
        res.statusCode < 300 &&
        map['success'] == true) {
      final data = map['data'] ?? {};
      // ✅ เพิ่มตรวจสอบ proofImageUrl ให้แน่ใจว่ามีเสมอ
      return {
        ...data,
        'proofImageUrl':
            data['proofImageUrl'] ??
            data['proof_image'] ??
            '', // fallback ป้องกัน null
      };
    } else {
      throw Exception(map['message'] ?? 'ไม่สามารถโหลดรายละเอียดพัสดุได้');
    }
  }

  // ✅ 7. ดึงรายชื่อผู้ใช้และไรเดอร์ทั้งหมด
  Future<List<Map<String, dynamic>>> getAllContacts() async {
    final uri = Uri.parse('$baseUrl/api/users/all');
    final res = await http.get(uri, headers: await _authHeader());
    final map = json.decode(res.body);

    if (res.statusCode >= 200 &&
        res.statusCode < 300 &&
        map['success'] == true) {
      return List<Map<String, dynamic>>.from(map['data'] ?? []);
    } else {
      throw Exception(map['message'] ?? 'ไม่สามารถโหลดรายชื่อผู้ใช้ได้');
    }
  }

  // ดึงพัสดุทั้งหมดที่ฉันส่ง → คืนค่าเป็น List<Order>
  Future<List<Order>> getSenderOrders(String senderId) async {
    final parcels = await getSenderParcels(senderId);
    return parcels.map((json) => Order.fromJson(json)).toList();
  }

  // ดึงพัสดุทั้งหมดที่ฉันเป็นผู้รับ → คืนค่าเป็น List<Order>
  Future<List<Order>> getReceiverOrders(String receiverId) async {
    final parcels = await getReceiverParcels(receiverId);
    return parcels.map((json) => Order.fromJson(json)).toList();
  }

  Future<bool> updateOrderStatusWithImage({
    required String orderId,
    required int newStatus,
    String? imagePath, // ใส่รูปถ้ามี
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/orders/$orderId/status');
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['status'] = newStatus.toString();

      if (imagePath != null &&
          imagePath.isNotEmpty &&
          File(imagePath).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Update status failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating status: $e');
      return false;
    }
  }

  // ใช้สำหรับ Pickup
  Future<bool> updateOrderPickup({
    required String orderId,
    String? pickupImagePath,
  }) {
    return updateOrderStatusWithImage(
      orderId: orderId,
      newStatus: 3, // กำลังส่ง
      imagePath: pickupImagePath,
    );
  }

  // ใช้สำหรับ Delivery
  Future<bool> updateOrderDelivery({
    required String orderId,
    String? deliveryImagePath,
  }) {
    return updateOrderStatusWithImage(
      orderId: orderId,
      newStatus: 4, // ส่งสำเร็จ
      imagePath: deliveryImagePath,
    );
  }

  // ---------------------------------------------------------------------------
  // 🔹 อัปเดตสถานะ + อัปโหลดรูป
  // ---------------------------------------------------------------------------
  // OrdersService.dart
  Future<bool> updateOrderStatus({
    required String orderId,
    required int newStatus,
    Uint8List? image,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/orders/$orderId/status'),
      );
      request.headers['Authorization'] = 'Bearer $token'; // ใช้ token ของ class
      request.fields['status'] = newStatus.toString();

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

      return res.statusCode == 200;
    } catch (e) {
      print('Error updating status: $e');
      return false;
    }
  }
}
