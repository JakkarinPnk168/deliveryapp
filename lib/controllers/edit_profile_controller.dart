import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class EditProfileController extends ChangeNotifier {
  final ApiService api;
  final Future<String?> Function() tokenProvider;

  EditProfileController({required this.api, required this.tokenProvider});

  bool loading = false;
  bool saving = false;
  String? errorMessage;

  UserModel? user;
  File? pickedImageFile;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> loadInitialData() async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await tokenProvider();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found');
      }

      final fetchedUser = await api.getMe(token);
      user = fetchedUser;

      nameController.text = fetchedUser.name;
      phoneController.text = fetchedUser.phone ?? '';
    } catch (e) {
      errorMessage = 'โหลดข้อมูลไม่สำเร็จ: $e';
      debugPrint('❌ $errorMessage');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> pickImage() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 88,
    );
    if (x != null) {
      pickedImageFile = File(x.path);
      notifyListeners();
    }
  }

  Future<bool> save() async {
    if (saving) return false;

    saving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await tokenProvider();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found');
      }

      final updated = await api.updateProfile(
        token,
        name: nameController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        imageFile: pickedImageFile,
      );

      user = updated;
      nameController.text = updated.name;
      phoneController.text = updated.phone ?? '';

      saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'บันทึกไม่สำเร็จ: $e';
      saving = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
