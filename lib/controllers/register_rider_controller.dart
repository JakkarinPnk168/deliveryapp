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

  // แปลง +66xxxxxxxxx -> 0xxxxxxxxx และเก็บเฉพาะตัวเลข/+
  String _normalizePhone(String input) {
    var s = input.trim().replaceAll(RegExp(r'[^0-9\+]'), '');
    if (s.startsWith('+66')) s = '0${s.substring(3)}';
    return s;
  }

  /// เลือกรูปโปรไฟล์
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
    }
  }

  /// เลือกรูปยานพาหนะ
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
    }
  }

  /// สมัคร Rider (ส่ง multipart ไป backend)
  Future<bool> register(BuildContext context) async {
    if (isSubmitting) return false;

    final phone = _normalizePhone(phoneController.text);
    final name = nameController.text.trim();
    final pass = passwordController.text;
    final plate = vehiclePlateController.text.trim();

    // ✅ ตรวจสอบ input
    if (phone.isEmpty || name.isEmpty || pass.isEmpty || plate.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')));
      return false;
    }
    if (!RegExp(r'^[0]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกเบอร์โทรให้ถูกต้อง (เช่น 0812345678)'),
        ),
      );
      return false;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร')),
      );
      return false;
    }

    isSubmitting = true;
    try {
      await _authService.registerRider(
        phone: phone,
        password: pass,
        name: name,
        vehiclePlate: plate,
        profileImage: profileImage, // จะถูกอัปโหลดผ่าน backend → Cloudinary
        vehicleImage: vehicleImage,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('สมัคร Rider สำเร็จ')));
        Navigator.pop(context, true); // ส่ง true ให้หน้าก่อนหน้ารีเฟรชได้
      }
      return true;
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
      return false;
    } finally {
      isSubmitting = false;
    }
  }

  void dispose() {
    phoneController.dispose();
    nameController.dispose();
    passwordController.dispose();
    vehiclePlateController.dispose();
  }
}
