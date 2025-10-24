import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:awesome_dialog/awesome_dialog.dart'; // ✅ ใช้ AwesomeDialog แทน SweetAlert2
import '../controllers/edit_profile_controller.dart';
import '../services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final EditProfileController controller;
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  @override
  void initState() {
    super.initState();
    controller = EditProfileController(
      api: ApiService(),
      tokenProvider: _getToken,
    );
    controller.loadInitialData();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF20C65A);
    const lightBackground = Color(0xFFF2FAF5);

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Scaffold(
          backgroundColor: lightBackground,
          appBar: AppBar(
            backgroundColor: primaryGreen,
            elevation: 0,
            title: const Text(
              'แก้ไขโปรไฟล์',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(result: false),
            ),
          ),
          body: controller.loading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, primaryGreen),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, Color primaryGreen) {
    final user = controller.user;
    if (controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('เกิดข้อผิดพลาด: ${controller.errorMessage}'),
        ),
      );
    }
    if (user == null) {
      return const Center(child: Text('ไม่พบข้อมูลผู้ใช้'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          _avatarSection(user.profileImage, primaryGreen),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ชื่อ–สกุล',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.nameController,
                    decoration: InputDecoration(
                      hintText: 'กรอกชื่อที่แสดง',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'กรุณากรอกชื่อ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'เบอร์โทร',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'กรอกเบอร์โทร',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ✅ ปุ่มบันทึก
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: controller.saving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              final ok = await controller.save();

                              if (ok) {
                                AwesomeDialog(
                                  context: context,
                                  dialogType: DialogType.noHeader,
                                  animType: AnimType.bottomSlide,
                                  title: 'บันทึกสำเร็จ ',
                                  desc:
                                      'ข้อมูลโปรไฟล์ของคุณได้รับการอัปเดตแล้ว',
                                  btnOkText: 'ตกลง',
                                  btnOkColor: primaryGreen,
                                  btnOkOnPress: () {
                                    Get.back(result: true);
                                  },
                                ).show();
                              } else {
                                // ❌ แสดง popup error ด้วย AwesomeDialog
                                AwesomeDialog(
                                  context: context,
                                  dialogType: DialogType.error,
                                  animType: AnimType.bottomSlide,
                                  title: 'เกิดข้อผิดพลาด ❌',
                                  desc:
                                      controller.errorMessage ??
                                      'ไม่สามารถบันทึกข้อมูลได้',
                                  btnOkText: 'ปิด',
                                  btnOkColor: Colors.redAccent,
                                  btnOkOnPress: () {},
                                ).show();
                              }
                            },
                      child: controller.saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'บันทึก',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarSection(String? imageUrl, Color primaryGreen) {
    final File? file = controller.pickedImageFile;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: file != null
                  ? FileImage(file)
                  : (imageUrl != null && imageUrl.isNotEmpty)
                  ? NetworkImage(imageUrl) as ImageProvider
                  : const AssetImage('assets/profile_placeholder.png'),
            ),
            Positioned(
              bottom: 4,
              right: 6,
              child: InkWell(
                onTap: controller.pickImage,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
