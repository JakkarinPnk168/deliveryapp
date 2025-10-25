// lib/controllers/parcel_create_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:deliveryapp/config/app_config.dart';
import 'package:deliveryapp/models/parcel_item_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ParcelCreateController {
  final headers = {"Content-Type": "application/json"};

  /// 🚚 สร้างพัสดุใหม่ (Flutter → Node.js → Firebase)
  Future<Map<String, dynamic>> createParcel({
    required String senderId,
    required String receiverId,
    required ReceiverAddress receiverAddress,
    required List<ParcelItem> items,
    File? proofImage, // ✅ เพิ่มรูปหลักฐาน
  }) async {
    try {
      final uri = Uri.parse("${AppConfig.apiBaseUrl}/api/parcels");
      final request = http.MultipartRequest("POST", uri);

      // 🧭 Debug Log
      print("🚀 [CREATE PARCEL]");
      print("📦 Sender ID  : $senderId");
      print("📦 Receiver ID: $receiverId");
      print("📍 Address     : ${receiverAddress.toJson()}");
      print("🧾 Items Count : ${items.length}");

      if (senderId == receiverId) {
        print("⚠️ [เตือน] ผู้ส่งและผู้รับเป็นคนเดียวกัน!");
      }

      // ✅ ฟิลด์ข้อความ
      request.fields["senderId"] = senderId;
      request.fields["receiverId"] = receiverId;
      request.fields["receiverAddress"] = jsonEncode(receiverAddress.toJson());
      request.fields["items"] = jsonEncode(
        items.map((e) => e.toJson()).toList(),
      );

      // ✅ แนบรูปภาพสินค้า (ถ้ามี)
      for (final item in items) {
        if (item.imageFile != null && File(item.imageFile!.path).existsSync()) {
          print("🖼️ แนบรูปภาพสินค้า: ${item.imageFile!.path}");
          request.files.add(
            await http.MultipartFile.fromPath("images", item.imageFile!.path),
          );
        }
      }

      // ✅ แนบรูปหลักฐานการส่ง (จำเป็น)
      if (proofImage != null && File(proofImage.path).existsSync()) {
        print("📸 แนบรูปหลักฐาน: ${proofImage.path}");
        request.files.add(
          await http.MultipartFile.fromPath("proofImage", proofImage.path),
        );
      } else {
        print("⚠️ [เตือน] ไม่มีรูปหลักฐานแนบมาด้วย");
        return {
          "success": false,
          "message": "กรุณาถ่ายรูปหลักฐานก่อนสร้างพัสดุ",
        };
      }

      // ✅ ส่งคำขอไป Backend
      print("🌐 ส่งคำขอไปที่: $uri");
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📩 สถานะตอบกลับ: ${response.statusCode}");
      print("📨 ตอบกลับจากเซิร์ฟเวอร์: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body["success"] == true) {
          print("✅ สร้างพัสดุสำเร็จ: ${body["message"]}");
          return {
            "success": true,
            "message": body["message"] ?? "สร้างพัสดุสำเร็จ",
            "orderId": body["data"]?["orderId"],
            "data": body["data"],
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
      print("📞 [SEARCH RECEIVER] $uri");

      final res = await http.get(uri, headers: headers);
      print("📩 Status: ${res.statusCode}");
      print("📨 Response: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true) {
          print(
            "✅ พบผู้รับ: ${data['data']?['name']} (${data['data']?['userId']})",
          );
        }
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
      print("📦 [GET SENDER PARCELS] $uri");

      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true) {
          print("✅ พบ ${data['data']?.length ?? 0} พัสดุที่ส่ง");
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
      print("📦 [GET RECEIVER PARCELS] $uri");

      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true) {
          print("✅ พบ ${data['data']?.length ?? 0} พัสดุที่ได้รับ");
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

  /// 📸 อัปโหลดรูปหลักฐานการส่งสินค้า
  Future<Map<String, dynamic>> uploadProofImage(
    String orderId,
    File imageFile,
  ) async {
    try {
      final uri = Uri.parse(
        "${AppConfig.apiBaseUrl}/api/orders/$orderId/proof",
      );
      print("📤 [UPLOAD PROOF] $uri");

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print("📩 สถานะตอบกลับ: ${response.statusCode}");
      print("📨 ตอบกลับจากเซิร์ฟเวอร์: ${response.body}");

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

  /// 👥 ดึงรายชื่อผู้ใช้และไรเดอร์ทั้งหมด (ใช้ใน Dropdown ผู้รับ)
  Future<List<Map<String, dynamic>>> getAllContacts() async {
    try {
      // ✅ ดึง userId ปัจจุบันจาก SecureStorage
      final storage = const FlutterSecureStorage();
      final currentUserId = await storage.read(key: "userId");

      // ✅ สร้าง URI ที่ปลอดภัย (รองรับ uid)
      final uri = Uri.parse(
        "${AppConfig.apiBaseUrl}/api/users/all${currentUserId != null ? '?uid=$currentUserId' : ''}",
      );

      final headers = {"Content-Type": "application/json"};
      print("🌐 [GET ALL CONTACTS] เรียกใช้งาน: $uri");

      // ✅ ส่งคำขอ GET ไปยัง backend
      final res = await http.get(uri, headers: headers);

      print("📩 [RESPONSE STATUS] ${res.statusCode}");

      // ✅ ตรวจสอบว่า API ตอบกลับ 200
      if (res.statusCode == 200) {
        Map<String, dynamic>? data;
        try {
          data = jsonDecode(res.body);
        } catch (e) {
          print("⚠️ Response ไม่สามารถแปลง JSON ได้: ${res.body}");
          return [];
        }

        if (data?["success"] == true && data?["data"] is List) {
          final rawList = List<Map<String, dynamic>>.from(data!["data"]);

          // ✅ Normalize ข้อมูลให้เป็นรูปแบบเดียวกัน
          final list = rawList.map((user) {
            final uid = user["userId"] ?? user["id"] ?? "";
            return {
              ...user,
              "id": uid,
              "userId": uid,
              "name": user["name"] ?? "ไม่ระบุชื่อ",
              "phone": user["phone"] ?? "-",
              "profileImage": user["profileImage"] ?? "",
              "role": user["role"] ?? "user",
            };
          }).toList();

          // ✅ กรองตัวเองออกจากลิสต์ (ถ้ามี userId ปัจจุบัน)
          final filtered = currentUserId != null
              ? list.where((u) => u["id"] != currentUserId).toList()
              : list;

          print("✅ โหลดรายชื่อผู้ใช้สำเร็จ: ${filtered.length} รายการ");
          print("   (กรอง userId ตัวเองออกแล้ว: $currentUserId)");

          return filtered;
        } else {
          print("⚠️ API success=false หรือ data ไม่ใช่ List: ${res.body}");
          return [];
        }
      }

      print("❌ โหลดรายชื่อผู้ใช้ไม่สำเร็จ (${res.statusCode}): ${res.body}");
      return [];
    } catch (e) {
      print("🔥 Error getAllContacts: $e");
      return [];
    }
  }
}
