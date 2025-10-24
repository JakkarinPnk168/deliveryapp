import 'package:get/get.dart';
import 'package:deliveryapp/services/orders_service.dart';
import 'dart:io';

class ParcelController extends GetxController {
  final OrdersService _ordersService = OrdersService();

  // 🔹 state
  var isLoading = false.obs;
  var hasError = false.obs;

  // 🔹 list สำหรับพัสดุ
  var senderParcels = <Map<String, dynamic>>[].obs;
  var receiverParcels = <Map<String, dynamic>>[].obs;

  /// 📨 โหลดพัสดุของ "ผู้ส่ง"
  Future<void> fetchSenderParcels(String senderId) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final result = await _ordersService.getSenderParcels(senderId);

      if (result.isNotEmpty) {
        // ✅ จัดเรียงตามวันที่ล่าสุด
        result.sort((a, b) {
          final timeA = _parseCreatedAt(a['createdAt']);
          final timeB = _parseCreatedAt(b['createdAt']);
          return timeB.compareTo(timeA);
        });
        senderParcels.assignAll(result);
      } else {
        senderParcels.clear();
      }
    } catch (e) {
      hasError.value = true;
      print("🔥 Error fetchSenderParcels: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// 📦 โหลดพัสดุของ "ผู้รับ"
  Future<void> fetchReceiverParcels(String receiverId) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final result = await _ordersService.getReceiverParcels(receiverId);

      if (result.isNotEmpty) {
        result.sort((a, b) {
          final timeA = _parseCreatedAt(a['createdAt']);
          final timeB = _parseCreatedAt(b['createdAt']);
          return timeB.compareTo(timeA);
        });
        receiverParcels.assignAll(result);
      } else {
        receiverParcels.clear();
      }
    } catch (e) {
      hasError.value = true;
      print("🔥 Error fetchReceiverParcels: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// 🕓 helper: แปลง createdAt จาก Firestore
  int _parseCreatedAt(dynamic createdAt) {
    try {
      if (createdAt == null) return 0;

      // ✅ Firestore Timestamp Map เช่น { _seconds: 1730000000, _nanoseconds: 0 }
      if (createdAt is Map && createdAt.containsKey('_seconds')) {
        final raw = createdAt['_seconds'];
        if (raw is int) return raw * 1000;
        if (raw is double) return raw.toInt() * 1000;
        if (raw is String) return (int.tryParse(raw) ?? 0) * 1000;
      }

      // ✅ Firestore Timestamp object
      if (createdAt.runtimeType.toString().contains('Timestamp')) {
        try {
          return (createdAt as dynamic).toDate().millisecondsSinceEpoch;
        } catch (_) {}
      }

      // ✅ ISO string เช่น "2025-10-25T10:12:00Z"
      if (createdAt is String) {
        try {
          return DateTime.parse(createdAt).millisecondsSinceEpoch;
        } catch (_) {
          return int.tryParse(createdAt) ?? 0;
        }
      }

      // ✅ ตัวเลข timestamp โดยตรง (int/double)
      if (createdAt is num) {
        // ถ้ามีค่ามากกว่า 13 หลักคือ milliseconds
        return createdAt > 1000000000000
            ? createdAt.toInt()
            : (createdAt * 1000).toInt();
      }

      return 0;
    } catch (e) {
      print("⚠️ parseCreatedAt error: $e (value=$createdAt)");
      return 0;
    }
  }

  /// 📷 อัปโหลดหลักฐาน (เชื่อมต่อกับ OrdersService)
  Future<void> uploadProof(String orderId, String imagePath) async {
    try {
      isLoading.value = true;
      await _ordersService.uploadProof(orderId, File(imagePath));
      print("✅ อัปโหลดหลักฐานสำเร็จ: $orderId");
    } catch (e) {
      print("🔥 uploadProof error: $e");
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}
