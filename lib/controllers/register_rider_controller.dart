import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class RegisterRiderController {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController vehiclePlateController = TextEditingController();

  File? profileImage;
  File? vehicleImage;
  bool isSubmitting = false;

  final AuthService _authService;
  RegisterRiderController({AuthService? authService})
    : _authService = authService ?? AuthService();

  /// ✅ แปลงเบอร์ +66 → 0 และเก็บเฉพาะตัวเลข
  String _normalizePhone(String input) {
    var s = input.trim().replaceAll(RegExp(r'[^0-9\+]'), '');
    if (s.startsWith('+66')) s = '0${s.substring(3)}';
    return s;
  }

  /// ✅ แสดง SnackBar
  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// ✅ เลือกรูปโปรไฟล์
  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (picked != null) {
      profileImage = File(picked.path);
      debugPrint('📷 โปรไฟล์: ${picked.path}');
    } else {
      debugPrint('❌ ไม่มีรูปโปรไฟล์ที่เลือก');
    }
  }

  /// ✅ เลือกรูปยานพาหนะ
  Future<void> pickVehicleImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (picked != null) {
      vehicleImage = File(picked.path);
      debugPrint('🚚 ยานพาหนะ: ${picked.path}');
    } else {
      debugPrint('❌ ไม่มีรูปรถที่เลือก');
    }
  }

  /// ✅ สมัคร Rider (multipart + handle backend)
  Future<bool> register(BuildContext context) async {
    if (isSubmitting) return false;

    final phone = _normalizePhone(phoneController.text);
    final name = nameController.text.trim();
    final pass = passwordController.text.trim();
    final plate = vehiclePlateController.text.trim();

    // 🔍 ตรวจสอบ input เบื้องต้น
    if (phone.isEmpty || name.isEmpty || pass.isEmpty || plate.isEmpty) {
      _showSnack(context, 'กรุณากรอกข้อมูลให้ครบ');
      return false;
    }

    // 🔍 ตรวจสอบเบอร์โทร (ต้องเป็น 0XXXXXXXXX)
    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      _showSnack(context, 'กรุณากรอกเบอร์โทรให้ถูกต้อง (เช่น 0812345678)');
      return false;
    }

    if (pass.length < 6) {
      _showSnack(context, 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
      return false;
    }

    isSubmitting = true;

    try {
      await _authService.registerRider(
        phone: phone,
        password: pass,
        name: name,
        vehiclePlate: plate,
        profileImage: profileImage,
        vehicleImage: vehicleImage,
      );

      if (context.mounted) {
        _showSnack(context, 'สมัคร Rider สำเร็จ 🎉');
        Navigator.pop(context, true);
      }
      return true;
    } on ApiException catch (e) {
      final msg = e.message;

      // ✅ แปลข้อความจาก backend ให้ user เข้าใจ
      if (msg.contains('Rider แล้ว')) {
        _showSnack(context, 'เบอร์นี้ถูกใช้งานในบัญชี Rider แล้ว');
      } else if (msg.contains('ผู้ใช้แล้ว')) {
        _showSnack(
          context,
          'เบอร์นี้มีในบัญชีผู้ใช้แล้ว (สามารถใช้สมัคร Rider ได้)',
        );
      } else {
        _showSnack(context, msg);
      }
      return false;
    } catch (e) {
      _showSnack(context, 'เกิดข้อผิดพลาด: $e');
      return false;
    } finally {
      isSubmitting = false;
    }
  }

  /// ✅ กำหนดเบอร์อัตโนมัติ (เช่น จากหน้า User ที่ส่งมา)
  void setInitialPhone(String? phone) {
    if (phone != null && phone.isNotEmpty) {
      phoneController.text = _normalizePhone(phone);
      debugPrint('📱 ตั้งค่าเบอร์อัตโนมัติ: ${phoneController.text}');
    }
  }

  void dispose() {
    phoneController.dispose();
    nameController.dispose();
    passwordController.dispose();
    vehiclePlateController.dispose();
  }
}
