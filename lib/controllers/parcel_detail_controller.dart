import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:deliveryapp/services/orders_service.dart';

class ParcelDetailController extends GetxController {
  final OrdersService _ordersService = OrdersService();

  // 🔹 State
  var isLoading = false.obs;
  var hasError = false.obs;

  // 🔹 ข้อมูลรายละเอียดพัสดุ
  var parcel = {}.obs;

  // 🔹 ตำแหน่งของผู้รับ (ใช้สำหรับ Map)
  var receiverPosition = Rxn<LatLng>();

  /// ✅ โหลดรายละเอียดพัสดุตาม orderId
  Future<void> fetchParcelDetail(String orderId) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final data = await _ordersService.getParcelDetail(orderId);

      if (data != null && data.isNotEmpty) {
        // ✅ ดึง address และ proof image ให้ปลอดภัย
        final address = data['address'] ?? {};
        final proofImage = data['proofImageUrl'] ?? data['proof_image'] ?? '';

        // ✅ ปรับ lat/lng ให้เป็น double ปลอดภัย
        final lat = double.tryParse(address['lat']?.toString() ?? '0') ?? 0;
        final lng = double.tryParse(address['lng']?.toString() ?? '0') ?? 0;

        // ✅ อัปเดตค่า parcel ทั้งหมด
        parcel.value = {
          ...data,
          'address': {...address, 'lat': lat, 'lng': lng},
          'proofImageUrl': proofImage,
        };

        // ✅ ตั้งตำแหน่งผู้รับในแผนที่
        if (lat != 0 && lng != 0) {
          receiverPosition.value = LatLng(lat, lng);
        } else {
          receiverPosition.value = null;
        }

        print("✅ โหลดรายละเอียดพัสดุสำเร็จ: ${data['orderId']}");
        print("📍 พิกัดผู้รับ: ($lat, $lng)");
        if (proofImage.isNotEmpty) {
          print("📸 มีรูปหลักฐานแนบ: $proofImage");
        } else {
          print("⚠️ ไม่มีรูปหลักฐานในพัสดุนี้");
        }
      } else {
        parcel.value = {};
        hasError.value = true;
        print("⚠️ ไม่พบข้อมูลพัสดุใน response");
      }
    } catch (e) {
      print("🔥 Error fetchParcelDetail: $e");
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// 🏷️ ดึงข้อความสถานะ
  String statusText(dynamic s) {
    if (s == 1) return "รอไรเดอร์รับสินค้า";
    if (s == 2) return "กำลังจัดส่ง";
    if (s == 3) return "จัดส่งสำเร็จ";
    if (s == 4) return "ยกเลิกการจัดส่ง";
    return "รอการยืนยัน";
  }

  /// 🎨 สีสถานะ
  int statusColor(dynamic s) {
    if (s == 1) return 0xFFFFA726; // ส้ม
    if (s == 2) return 0xFF42A5F5; // ฟ้า
    if (s == 3) return 0xFF66BB6A; // เขียว
    if (s == 4) return 0xFFE57373; // แดง (ยกเลิก)
    return 0xFF9E9E9E; // เทา (default)
  }
}
