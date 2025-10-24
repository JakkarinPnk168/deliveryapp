// lib/controllers/parcel_create_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:deliveryapp/config/app_config.dart';
import 'package:deliveryapp/models/parcel_item_model.dart';

class ParcelCreateController {
  final headers = {"Content-Type": "application/json"};

  /// 🚚 สร้างพัสดุใหม่ (Flutter → Node.js → Firebase)
  Future<Map<String, dynamic>> createParcel({
    required String senderId,
    required String receiverId,
    required ReceiverAddress receiverAddress,
    required List<ParcelItem> items,
  }) async {
    try {
      final uri = Uri.parse("${AppConfig.apiBaseUrl}/api/parcels");
      final request = http.MultipartRequest("POST", uri);

      // ✅ ฟิลด์ text
      request.fields["senderId"] = senderId;
      request.fields["receiverId"] = receiverId;
      request.fields["receiverAddress"] = jsonEncode(receiverAddress.toJson());
      request.fields["items"] = jsonEncode(
        items.map((e) => e.toJson()).toList(),
      );

      // ✅ แนบรูปภาพสินค้า
      for (final item in items) {
        if (item.imageFile != null && File(item.imageFile!.path).existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath("images", item.imageFile!.path),
          );
        }
      }

      // ✅ ส่งคำขอไป Backend
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body["success"] == true) {
          print("✅ สร้างพัสดุสำเร็จ: ${body["message"]}");
          return {
            "success": true,
            "message": body["message"] ?? "สร้างพัสดุสำเร็จ",
            "orderIds": body["orderIds"] ?? [],
            "data": body,
          };
        } else {
          print("⚠️ สร้างพัสดุไม่สำเร็จ: ${body["message"]}");
          return {"success": false, "message": body["message"] ?? "ไม่สำเร็จ"};
        }
      } else {
        print("❌ สร้างพัสดุล้มเหลว (${response.statusCode})");
        return {"success": false, "message": response.body};
      }
    } catch (e) {
      print("🔥 Error createParcel: $e");
      return {"success": false, "error": e.toString()};
    }
  }

  /// 🔍 ค้นหาผู้รับจากหมายเลขโทรศัพท์
  Future<Map<String, dynamic>?> searchReceiver(String phone) async {
    try {
      final uri = Uri.parse(
        "${AppConfig.apiBaseUrl}/api/users/search?phone=$phone",
      );
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data;
      }
      print("❌ ค้นหาผู้รับไม่สำเร็จ: ${res.body}");
      return null;
    } catch (e) {
      print("🔥 Error searchReceiver: $e");
      return null;
    }
  }

  /// 📦 ดึงรายการพัสดุของ "ผู้ส่ง"
  Future<List<dynamic>> getSenderParcels(String senderId) async {
    try {
      final uri = Uri.parse(
        "${AppConfig.apiBaseUrl}/api/parcels/sender/$senderId",
      );
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true) {
          return data['data'] ?? [];
        }
      }
      print("❌ โหลดพัสดุผู้ส่งไม่สำเร็จ: ${res.body}");
      return [];
    } catch (e) {
      print("🔥 Error getSenderParcels: $e");
      return [];
    }
  }

  /// 📦 ดึงรายการพัสดุของ "ผู้รับ"
  Future<List<dynamic>> getReceiverParcels(String receiverId) async {
    try {
      final uri = Uri.parse(
        "${AppConfig.apiBaseUrl}/api/parcels/receiver/$receiverId",
      );
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true) {
          return data['data'] ?? [];
        }
      }
      print("❌ โหลดพัสดุผู้รับไม่สำเร็จ: ${res.body}");
      return [];
    } catch (e) {
      print("🔥 Error getReceiverParcels: $e");
      return [];
    }
  }

  /// 📸 อัปโหลดรูปหลักฐาน (Proof of Delivery)
  Future<Map<String, dynamic>> uploadProofImage(
    String orderId,
    File imageFile,
  ) async {
    try {
      final uri = Uri.parse(
        "${AppConfig.apiBaseUrl}/api/orders/$orderId/proof",
      );

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          print("✅ อัปโหลดรูปหลักฐานสำเร็จ");
          return {"success": true, "data": data};
        }
      }
      print("❌ อัปโหลดรูปหลักฐานไม่สำเร็จ: ${response.body}");
      return {"success": false, "message": response.body};
    } catch (e) {
      print("🔥 Error uploadProofImage: $e");
      return {"success": false, "message": e.toString()};
    }
  }

  /// 👥 ดึงรายชื่อผู้ใช้และไรเดอร์ทั้งหมด (ใช้สำหรับ Dropdown เลือกผู้รับ)
  Future<List<Map<String, dynamic>>> getAllContacts() async {
    try {
      final uri = Uri.parse("${AppConfig.apiBaseUrl}/api/users/all");
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true) {
          final list = List<Map<String, dynamic>>.from(data["data"] ?? []);
          print("✅ โหลดรายชื่อผู้ใช้ทั้งหมดสำเร็จ (${list.length} รายการ)");
          return list;
        }
      }

      print("❌ โหลดรายชื่อผู้ใช้ไม่สำเร็จ: ${res.body}");
      return [];
    } catch (e) {
      print("🔥 Error getAllContacts: $e");
      return [];
    }
  }
}
