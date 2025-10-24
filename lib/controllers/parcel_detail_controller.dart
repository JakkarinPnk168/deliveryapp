import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:deliveryapp/services/orders_service.dart';

class ParcelDetailController extends GetxController {
  // final OrdersService _ordersService = OrdersService(token);
  late final OrdersService _ordersService;

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

      if (data.isNotEmpty) {
        // ✅ ตรวจสอบและจัดโครงสร้างข้อมูลให้ปลอดภัย
        final address = data['address'] ?? {};
        final proofImage = data['proofImageUrl'] ?? data['proof_image'] ?? "";

        parcel.value = {
          ...data,
          'address': address,
          'proofImageUrl': proofImage,
        };

        // ✅ ตั้งตำแหน่งผู้รับในแผนที่
        if (address.isNotEmpty) {
          receiverPosition.value = LatLng(
            (address['lat'] ?? 0).toDouble(),
            (address['lng'] ?? 0).toDouble(),
          );
        }
      } else {
        parcel.value = {};
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
