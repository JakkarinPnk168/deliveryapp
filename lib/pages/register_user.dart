import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/register_user_controller.dart';

class RegisterUserPage extends StatefulWidget {
  const RegisterUserPage({super.key});

  @override
  State<RegisterUserPage> createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends State<RegisterUserPage> {
  final controller = RegisterUserController();
  bool _loading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _onPickImage() async {
    await controller.pickProfileImage();
    if (!mounted) return;
    setState(() {}); // refresh preview
  }

  Future<void> _onSubmit() async {
    if (_loading) return;
    setState(() => _loading = true);
    final ok = await controller.register(
      context,
    ); // จะ pop(context, true) เองเมื่อสำเร็จ
    if (!mounted) return; // เผื่อถูก pop ไปแล้ว
    if (!ok) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_loading;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Text(
                      "RegisterUser",
                      style: GoogleFonts.cherryBombOne(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ✅ CircleAvatar Preview
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: controller.profileImage != null
                        ? FileImage(controller.profileImage!)
                        : null,
                    child: controller.profileImage == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // เบอร์โทร (รับเฉพาะตัวเลขหรือ +)
                  TextField(
                    enabled: !_loading,
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\+]')),
                      LengthLimitingTextInputFormatter(12),
                    ],
                    decoration: InputDecoration(
                      labelText: "เบอร์โทร",
                      labelStyle: const TextStyle(color: Colors.green),
                      hintText:
                          "กรอกเบอร์โทร (เช่น 0812345678 หรือ +66812345678)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ชื่อ-สกุล
                  TextField(
                    enabled: !_loading,
                    controller: controller.nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: "ชื่อ-สกุล",
                      labelStyle: const TextStyle(color: Colors.green),
                      hintText: "กรอกชื่อ-สกุล",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // รหัสผ่าน
                  TextField(
                    enabled: !_loading,
                    controller: controller.passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "รหัสผ่าน",
                      labelStyle: const TextStyle(color: Colors.green),
                      hintText: "กรอกรหัสผ่าน (อย่างน้อย 6 ตัว)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ปุ่มอัปโหลดรูปโปรไฟล์
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _onPickImage,
                      icon: const Icon(Icons.upload_file, color: Colors.grey),
                      label: const Text(
                        "อัปโหลดรูป",
                        style: TextStyle(color: Colors.grey),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ปุ่มสมัครสมาชิก
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: canSubmit ? _onSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _loading ? "กำลังสมัคร..." : "สมัครสมาชิก",
                        style: GoogleFonts.cherryBombOne(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ไปหน้า Login
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: Text(
                      "มีบัญชีแล้ว",
                      style: GoogleFonts.cherryBombOne(
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loading overlay
            if (_loading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.15),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
