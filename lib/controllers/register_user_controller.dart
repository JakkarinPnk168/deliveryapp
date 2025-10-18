import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class RegisterUserController {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  File? profileImage;
  bool isSubmitting = false;

  final AuthService _authService;
  RegisterUserController({AuthService? authService})
    : _authService = authService ?? AuthService();

  // แปลง +66xxxxxxxxx -> 0xxxxxxxxx และเก็บเฉพาะตัวเลข/+
  String _normalizePhone(String input) {
    var s = input.trim().replaceAll(RegExp(r'[^0-9\+]'), '');
    if (s.startsWith('+66')) s = '0${s.substring(3)}';
    return s;
  }

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked != null) {
      profileImage = File(picked.path);
      debugPrint("📷 เลือกรูปแล้ว: ${picked.path}");
    } else {
      debugPrint("❌ ไม่มีไฟล์ที่เลือก");
    }
  }

  Future<bool> register(BuildContext context) async {
    if (isSubmitting) return false;

    final phone = _normalizePhone(phoneController.text);
    final name = nameController.text.trim();
    final pass = passwordController.text;

    // ตรวจสอบ input
    if (phone.isEmpty || name.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบ")));
      return false;
    }
    // เบอร์ไทย 10 หลักขึ้นต้น 0
    if (!RegExp(r'^[0]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณากรอกเบอร์โทรให้ถูกต้อง (เช่น 0812345678)"),
        ),
      );
      return false;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร")),
      );
      return false;
    }

    isSubmitting = true;
    try {
      await _authService.registerUser(
        phone: phone,
        password: pass,
        name: name,
        profileImage: profileImage, // ส่งเป็น multipart ให้ backend
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("สมัครสมาชิกสำเร็จ")));
        Navigator.pop(
          context,
          true,
        ); // ส่ง true กลับไปให้หน้าก่อนรู้ว่ามีการสมัครสำเร็จ
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
        ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
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
  }
}
