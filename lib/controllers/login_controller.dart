import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginController {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Helper: เบอร์ → email
  String _emailFromPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return "$digits@lb.app";
  }

  // ✅ ฟังก์ชันเข้าสู่ระบบ
  Future<void> login(BuildContext context) async {
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกเบอร์โทรและรหัสผ่าน")),
      );
      return;
    }

    try {
      final email = _emailFromPhone(phone);
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      // ✅ ตรวจสอบ role
      String role = "user"; // default
      final userDoc = await _db.collection("users").doc(uid).get();
      if (userDoc.exists) {
        role = userDoc['role'] ?? "user";
      } else {
        final riderDoc = await _db.collection("riders").doc(uid).get();
        if (riderDoc.exists) {
          role = riderDoc['role'] ?? "rider";
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เข้าสู่ระบบสำเร็จ ($role)")));

      if (role == "user") {
        Navigator.pushReplacementNamed(context, "/homeUser");
      } else {
        Navigator.pushReplacementNamed(context, "/homeRider");
      }
    } on FirebaseAuthException catch (e) {
      String message = "เกิดข้อผิดพลาด";
      if (e.code == "user-not-found") {
        message = "ไม่พบบัญชีนี้ กรุณาสมัครสมาชิก";
      } else if (e.code == "wrong-password") {
        message = "รหัสผ่านไม่ถูกต้อง";
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }
  }

  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
  }
}
