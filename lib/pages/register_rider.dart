import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/register_rider_controller.dart';

class RegisterRiderPage extends StatefulWidget {
  const RegisterRiderPage({super.key});

  @override
  State<RegisterRiderPage> createState() => _RegisterRiderPageState();
}

class _RegisterRiderPageState extends State<RegisterRiderPage> {
  final controller = RegisterRiderController();

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
              const SizedBox(height: 60),
              Text(
                "RegisterRider",
                style: GoogleFonts.cherryBombOne(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 40),

              // เบอร์โทร
              TextField(
                controller: controller.phoneController,
                decoration: InputDecoration(
                  labelText: "เบอร์โทร",
                  labelStyle: const TextStyle(color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              // ชื่อ-สกุล
              TextField(
                controller: controller.nameController,
                decoration: InputDecoration(
                  labelText: "ชื่อ-สกุล",
                  labelStyle: const TextStyle(color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // รหัสผ่าน
              TextField(
                controller: controller.passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "รหัสผ่าน",
                  labelStyle: const TextStyle(color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // รูปโปรไฟล์
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: controller.profileImage != null
                        ? FileImage(controller.profileImage!)
                        : null,
                    child: controller.profileImage == null
                        ? const Icon(Icons.person, size: 30, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await controller.pickProfileImage();
                        setState(() {});
                      },
                      icon: const Icon(Icons.upload_file, color: Colors.grey),
                      label: const Text(
                        "อัปโหลดรูปโปรไฟล์",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // รูปยานพาหนะ
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: controller.vehicleImage != null
                        ? FileImage(controller.vehicleImage!)
                        : null,
                    child: controller.vehicleImage == null
                        ? const Icon(
                            Icons.directions_bike,
                            size: 30,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await controller.pickVehicleImage();
                        setState(() {});
                      },
                      icon: const Icon(Icons.upload_file, color: Colors.grey),
                      label: const Text(
                        "อัปโหลดรูปยานพาหนะ",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // เลขทะเบียนรถ
              TextField(
                controller: controller.vehiclePlateController,
                decoration: InputDecoration(
                  labelText: "ทะเบียนรถ",
                  labelStyle: const TextStyle(color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ปุ่มสมัคร Rider
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
                    "สมัครไรเดอร์",
                    style: GoogleFonts.cherryBombOne(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ปุ่มกลับไป Login
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
