import 'dart:convert';
import 'dart:io';
import 'package:deliveryapp/models/order_model.dart';
import 'package:http/http.dart' as http;

class OrderService {
  final String baseUrl = "http://192.168.1.105:3000";
  final String token;

  OrderService(this.token) {
    if (token.isEmpty) {
      throw Exception('Token is missing! Please login first.');
    }
  }

  // ดึงคำสั่งซื้อทั้งหมดสำหรับ Rider
  Future<List<Order>> getRiderOrders() async {
    final url = Uri.parse('$baseUrl/api/orders/rider');
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final orders = (data['data'] as List)
          .map((e) => Order.fromJson(e))
          .toList();
      return orders;
    } else {
      throw Exception('Failed to fetch orders: ${res.body}');
    }
  }

  // อัปโหลดรูปภาพทั่วไป
  Future<String?> uploadImage(String imagePath) async {
    try {
      final url = Uri.parse('$baseUrl/api/upload/image');
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['imageUrl'];
      } else {
        print('Upload failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // อัปเดตสถานะคำสั่งซื้อพร้อมรูป (สำหรับ Pickup หรือ Delivery)
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

  // อัปเดตสถานะแบบไม่ส่งรูป
  Future<bool> updateOrderStatus({
    required String orderId,
    required int newStatus,
  }) async {
    return updateOrderStatusWithImage(orderId: orderId, newStatus: newStatus);
  }

  // ดึงข้อมูลคำสั่งซื้อเดียว
  Future<Order?> getOrderById(String orderId) async {
    try {
      final url = Uri.parse('$baseUrl/api/orders/$orderId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Order.fromJson(data['data']);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }
}
