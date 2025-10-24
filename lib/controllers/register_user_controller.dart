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

  /// ✅ แปลงเบอร์ +66 → 0 และเก็บเฉพาะตัวเลข
  String _normalizePhone(String input) {
    var s = input.trim().replaceAll(RegExp(r'[^0-9\+]'), '');
    if (s.startsWith('+66')) s = '0${s.substring(3)}';
    return s;
  }

  /// ✅ เปิดเลือกรูปโปรไฟล์
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

  /// ✅ สมัครสมาชิก User (ตรวจสอบเบอร์ก่อน)
  Future<bool> register(BuildContext context) async {
    if (isSubmitting) return false;

    final phone = _normalizePhone(phoneController.text);
    final name = nameController.text.trim();
    final pass = passwordController.text.trim();

    // 🔍 ตรวจสอบ input
    if (phone.isEmpty || name.isEmpty || pass.isEmpty) {
      _showSnack(context, "กรุณากรอกข้อมูลให้ครบ");
      return false;
    }

    // 🔍 ตรวจสอบเบอร์โทร
    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      _showSnack(context, "กรุณากรอกเบอร์โทรให้ถูกต้อง (เช่น 0812345678)");
      return false;
    }

    if (pass.length < 6) {
      _showSnack(context, "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร");
      return false;
    }

    isSubmitting = true;

    try {
      // ✅ 1) ตรวจสอบเบอร์กับ backend ก่อน
      final check = await _authService.checkPhone(phone);
      final status = check['status'] ?? '';

      if (status == 'rider-exists' || status == 'both-exist') {
        _showSnack(context, "เบอร์นี้ถูกใช้งานในบัญชี Rider แล้ว");
        return false;
      }

      if (status == 'user-exists') {
        // 🔔 เสนอสมัคร Rider เพิ่ม
        await _showOptionDialog(context);
        return false;
      }

      // ✅ 2) สมัครได้ตามปกติ (status == available)
      await _authService.registerUser(
        phone: phone,
        password: pass,
        name: name,
        profileImage: profileImage,
      );

      if (context.mounted) {
        _showSnack(context, "สมัครสมาชิกสำเร็จ 🎉");
        Navigator.pop(context, true);
      }
      return true;
    } on ApiException catch (e) {
      _showSnack(context, e.message);
      return false;
    } catch (e) {
      _showSnack(context, "เกิดข้อผิดพลาด: $e");
      return false;
    } finally {
      isSubmitting = false;
    }
  }

  /// ✅ Dialog ถ้ามีเบอร์นี้อยู่ในระบบแล้ว — เสนอสมัคร Rider เพิ่ม
  Future<void> _showOptionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("เบอร์นี้มีในระบบแล้ว"),
        content: const Text(
          "คุณมีบัญชีผู้ใช้แล้ว ต้องการสมัครเป็น Rider เพิ่มหรือไม่?",
        ),
        actions: [
          TextButton(
            child: const Text("ยกเลิก"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("สมัคร Rider"),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/registerRider',
                arguments: phoneController.text,
              );
            },
          ),
        ],
      ),
    );
  }

  /// ✅ แสดงข้อความ SnackBar
  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void dispose() {
    phoneController.dispose();
    nameController.dispose();
    passwordController.dispose();
  }
}
