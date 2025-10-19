import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../models/address_model.dart';

class AddressAddController extends ChangeNotifier {
  final ApiService api;
  final Future<String?> Function() tokenProvider;

  AddressAddController({required this.api, required this.tokenProvider});

  // --- 🔹 สถานะ UI ---
  bool loading = false; // ใช้เผื่ออนาคตตอน preload data
  bool locating = false; // ระหว่างหาพิกัด
  bool saving = false; // ระหว่างบันทึก
  String? errorMessage; // แสดงข้อความ error บนหน้าจอ

  // --- 🔹 พิกัดที่เลือกบนแผนที่ ---
  LatLng? selectedLocation;

  // --- 🔹 Controllers สำหรับฟอร์มกรอกข้อมูลที่อยู่ ---
  final labelController = TextEditingController(); // เช่น "บ้าน", "ที่ทำงาน"
  final recipientNameController = TextEditingController(); // ชื่อผู้รับ
  final phoneController = TextEditingController();
  final addressDetailController = TextEditingController(); // บ้านเลขที่/ซอย/ถนน
  final subDistrictController = TextEditingController(); // แขวง/ตำบล
  final districtController = TextEditingController(); // เขต/อำเภอ
  final provinceController = TextEditingController(); // จังหวัด
  final postalCodeController = TextEditingController(); // รหัสไปรษณีย์

  // ---------------------------------------------------------------------------
  // 🔹 ตั้งค่าพิกัดที่เลือกบนแผนที่
  // ---------------------------------------------------------------------------
  void setSelected(LatLng position) {
    selectedLocation = position;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 🔹 ใช้ตำแหน่งปัจจุบัน (จาก Geolocator)
  // ---------------------------------------------------------------------------
  Future<void> useCurrentLocation(
    Future<LatLng?> Function() getCurrentPosition,
  ) async {
    locating = true;
    errorMessage = null;
    notifyListeners();

    try {
      final current = await getCurrentPosition();
      if (current != null) {
        selectedLocation = current;
      } else {
        errorMessage = 'ไม่สามารถดึงพิกัดปัจจุบันได้';
      }
    } catch (e) {
      errorMessage = 'เกิดข้อผิดพลาดระหว่างหาตำแหน่ง: ${e.toString()}';
    } finally {
      locating = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 บันทึกที่อยู่ใหม่
  // ---------------------------------------------------------------------------
  Future<bool> submit() async {
    if (saving) return false;
    if (selectedLocation == null) {
      errorMessage = 'กรุณาเลือกตำแหน่งบนแผนที่ก่อน';
      notifyListeners();
      return false;
    }

    // ตรวจค่าที่จำเป็นในฟอร์ม
    if (addressDetailController.text.trim().isEmpty) {
      errorMessage = 'กรุณากรอกข้อมูลที่อยู่ให้ครบถ้วน';
      notifyListeners();
      return false;
    }

    saving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await tokenProvider();
      if (token == null || token.isEmpty) {
        throw Exception('ไม่พบ Token กรุณาเข้าสู่ระบบใหม่');
      }

      // ✅ สร้าง AddressModel
      final address = AddressModel(
        id: '',
        label: labelController.text.trim().isEmpty
            ? 'ที่อยู่ใหม่'
            : labelController.text.trim(),
        recipientName: recipientNameController.text.trim(),
        phone: phoneController.text.trim(),
        addressLine: addressDetailController.text.trim(),
        subDistrict: subDistrictController.text.trim(),
        district: districtController.text.trim(),
        province: provinceController.text.trim(),
        postalCode: postalCodeController.text.trim(),
        lat: selectedLocation!.latitude,
        lng: selectedLocation!.longitude,
        isDefault: false,
      );

      // ✅ บันทึกผ่าน API → Firestore backend
      await api.createAddress(token, address);

      saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'บันทึกไม่สำเร็จ: ${e.toString()}';
      saving = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 ล้างข้อมูลเมื่อออกจากหน้า
  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    labelController.dispose();
    recipientNameController.dispose();
    phoneController.dispose();
    addressDetailController.dispose();
    subDistrictController.dispose();
    districtController.dispose();
    provinceController.dispose();
    postalCodeController.dispose();
    super.dispose();
  }
}
