import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/register_user_controller.dart';

class RegisterUserPage extends StatefulWidget {
  const RegisterUserPage({super.key});

  @override
  State<RegisterUserPage> createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends State<RegisterUserPage> {
  final controller = RegisterUserController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                    ? FileImage(controller.profileImage as File)
                    : null,
                child: controller.profileImage == null
                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
              ),

              const SizedBox(height: 20),

              // ช่องกรอกเบอร์โทร
              TextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "เบอร์โทร",
                  labelStyle: const TextStyle(color: Colors.green),
                  hintText: "กรอกเบอร์โทร",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ช่องกรอกชื่อ-สกุล
              TextField(
                controller: controller.nameController,
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

              // ช่องกรอกรหัสผ่าน
              TextField(
                controller: controller.passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "รหัสผ่าน",
                  labelStyle: const TextStyle(color: Colors.green),
                  hintText: "กรอกรหัสผ่าน",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ปุ่มอัพโหลดรูปโปรไฟล์
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await controller.pickProfileImage();
                    setState(() {}); // ✅ refresh UI ให้ CircleAvatar update
                  },
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
                  onPressed: () => controller.register(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "สมัครสมาชิก",
                    style: GoogleFonts.cherryBombOne(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ปุ่มไปหน้า Login
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
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
      ),
    );
  }
}
