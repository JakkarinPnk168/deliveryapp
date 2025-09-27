import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // ใส่ค่าจาก Cloudinary ของคุณ
  final String cloudName = "dbyohuyvi";
  final String presetProfiles = "profiles";
  final String presetVehicles = "vehicles";

  // ✅ Helper: เปลี่ยนเบอร์เป็นอีเมลเทียม
  String _emailFromPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$digits@lb.app';
  }

  // ✅ อัปโหลดรูปขึ้น Cloudinary
  Future<String?> _uploadToCloudinary(File file, String uploadPreset) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final data = json.decode(body);
      debugPrint("✅ Cloudinary Upload Success: ${data['secure_url']}");
      return data['secure_url'];
    } else {
      debugPrint("❌ Cloudinary Upload Failed: ${response.statusCode}");
      return null;
    }
  }

  // ✅ สมัครสมาชิก User
  Future<void> registerUser({
    required String phone,
    required String password,
    required String name,
    File? profileImage,
  }) async {
    final email = _emailFromPhone(phone);

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    String? profileUrl;
    if (profileImage != null) {
      profileUrl = await _uploadToCloudinary(profileImage, presetProfiles);
    }

    await _db.collection('users').doc(uid).set({
      'phone': phone,
      'name': name,
      'profile_img': profileUrl,
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint("✅ User registered successfully: $uid");
  }

  // ✅ สมัครสมาชิก Rider
  Future<void> registerRider({
    required String phone,
    required String password,
    required String name,
    File? profileImage,
    File? vehicleImage,
    required String vehiclePlate,
  }) async {
    final email = _emailFromPhone(phone);

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    String? profileUrl;
    if (profileImage != null) {
      profileUrl = await _uploadToCloudinary(profileImage, presetProfiles);
    }

    String? vehicleUrl;
    if (vehicleImage != null) {
      vehicleUrl = await _uploadToCloudinary(vehicleImage, presetVehicles);
    }

    await _db.collection('riders').doc(uid).set({
      'phone': phone,
      'name': name,
      'profile_img': profileUrl,
      'vehicle_image': vehicleUrl,
      'vehicle_plate': vehiclePlate,
      'role': 'rider',
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint("✅ Rider registered successfully: $uid");
  }
}
