import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // มี UserData และ ApiException อยู่ในไฟล์นี้

class LoginController {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService;
  bool isSubmitting = false;

  LoginController({AuthService? authService})
    : _authService = authService ?? AuthService();

  // แปลง +66xxxxxxxxx -> 0xxxxxxxxx และเก็บเฉพาะตัวเลข/+
  String _normalizePhone(String input) {
    var s = input.trim().replaceAll(RegExp(r'[^0-9\+]'), '');
    if (s.startsWith('+66')) s = '0${s.substring(3)}';
    return s;
  }

  Future<bool> login(BuildContext context) async {
    if (isSubmitting) return false;

    final phone = _normalizePhone(phoneController.text);
    final pass = passwordController.text;

    // ตรวจสอบ input
    if (phone.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกเบอร์โทรและรหัสผ่าน')),
      );
      return false;
    }
    // เบอร์ไทย 10 หลักขึ้นต้น 0
    if (!RegExp(r'^[0]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกเบอร์โทรให้ถูกต้อง (เช่น 0812345678)'),
        ),
      );
      return false;
    }

    isSubmitting = true;
    try {
      final UserData me = await _authService.login(
        phone: phone,
        password: pass,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เข้าสู่ระบบสำเร็จ (${me.role})')),
        );
        if (me.role == 'rider') {
          Navigator.pushReplacementNamed(context, '/homeRider');
        } else {
          Navigator.pushReplacementNamed(context, '/homeUser');
        }
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
    passwordController.dispose();
  }
}
