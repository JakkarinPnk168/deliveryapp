import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class RegisterRiderController {
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final vehiclePlateController = TextEditingController();

  File? profileImage;
  File? vehicleImage;

  final _authService = AuthService();

  /// เลือกรูปโปรไฟล์
  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      profileImage = File(picked.path);
    }
  }

  /// เลือกรูปยานพาหนะ
  Future<void> pickVehicleImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      vehicleImage = File(picked.path);
    }
  }

  /// สมัคร Rider
  Future<void> register(BuildContext context) async {
    try {
      await _authService.registerRider(
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        profileImage: profileImage,
        vehicleImage: vehicleImage,
        vehiclePlate: vehiclePlateController.text.trim(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("สมัคร Rider สำเร็จ")));
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
    vehiclePlateController.dispose();
  }
}
