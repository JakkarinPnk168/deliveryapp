import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class RegisterUserController {
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  File? profileImage;

  final _authService = AuthService();

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      profileImage = File(picked.path);
      debugPrint("📷 เลือกรูปแล้ว: ${picked.path}");
    } else {
      debugPrint("❌ ไม่มีไฟล์ที่เลือก");
    }
  }

  Future<void> register(BuildContext context) async {
    // ✅ ตรวจสอบ input ก่อน
    if (phoneController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบ")));
      return;
    }

    try {
      await _authService.registerUser(
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        profileImage: profileImage,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("สมัครสมาชิกสำเร็จ")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }
  }

  void dispose() {
    phoneController.dispose();
    nameController.dispose();
    passwordController.dispose();
  }
}
