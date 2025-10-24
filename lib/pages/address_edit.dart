import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/address_model.dart';
import '../services/api_service.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class AddressEditPage extends StatefulWidget {
  final String addressId;

  const AddressEditPage({super.key, required this.addressId});

  @override
  State<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<AddressEditPage> {
  final storage = const FlutterSecureStorage();
  final api = ApiService();

  final addressDetailCtrl = TextEditingController();
  final subDistrictCtrl = TextEditingController();
  final districtCtrl = TextEditingController();
  final provinceCtrl = TextEditingController();
  final postalCtrl = TextEditingController();

  bool loading = true;
  AddressModel? address;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  // 🔹 โหลดข้อมูลที่อยู่จาก backend
  Future<void> _loadAddress() async {
    final token = await storage.read(key: 'token');
    if (token == null || widget.addressId.isEmpty) return;

    try {
      final data = await api.getAddressById(token, widget.addressId);
      setState(() {
        address = data;
        loading = false;

        addressDetailCtrl.text = data.addressLine;
        subDistrictCtrl.text = data.subDistrict;
        districtCtrl.text = data.district;
        provinceCtrl.text = data.province;
        postalCtrl.text = data.postalCode;
      });
    } catch (e) {
      setState(() => loading = false);
      _showDialog(
        title: "เกิดข้อผิดพลาด",
        desc: e.toString(),
        color: Colors.redAccent,
        btnOkOnPress: () => Get.back(),
      );
    }
  }

  // 🔹 ฟังก์ชันอัปเดตข้อมูลที่อยู่
  Future<void> _updateAddress() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    try {
      await api.updateAddress(
        token,
        widget.addressId,
        address_detail: addressDetailCtrl.text.trim(),
        subDistrict: subDistrictCtrl.text.trim(),
        district: districtCtrl.text.trim(),
        province: provinceCtrl.text.trim(),
        postalCode: postalCtrl.text.trim(),
      );

      _showDialog(
        title: "อัปเดตสำเร็จ",
        desc: "ข้อมูลที่อยู่ได้รับการอัปเดตเรียบร้อยแล้ว",
        color: Colors.green,
        btnOkOnPress: () => Get.back(result: true),
      );
    } catch (e) {
      _showDialog(
        title: "เกิดข้อผิดพลาด",
        desc: e.toString(),
        color: Colors.redAccent,
      );
    }
  }

  Future<void> _deleteAddress() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.bottomSlide,
      title: "ลบที่อยู่",
      desc: "คุณแน่ใจหรือไม่ว่าต้องการลบที่อยู่นี้?",
      btnCancelText: "ยกเลิก",
      btnOkText: "ลบ",
      btnOkColor: Colors.red,
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        try {
          await api.deleteAddress(token, widget.addressId);

          Future.delayed(const Duration(milliseconds: 300), () {
            _showDialog(
              title: "ลบสำเร็จ",
              desc: "ที่อยู่ถูกลบออกเรียบร้อยแล้ว",
              color: Colors.green,
              btnOkOnPress: () => Get.back(result: true),
            );
          });
        } catch (e) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _showDialog(
              title: "ลบไม่สำเร็จ",
              desc: "ไม่สามารถลบที่อยู่ได้\n${e.toString()}",
              color: Colors.redAccent,
            );
          });
        }
      },
    ).show();
  }

  // 🔹 Helper เรียก AwesomeDialog แบบไม่มีหัววงกลม
  void _showDialog({
    required String title,
    required String desc,
    required Color color,
    String btnOkText = "ตกลง",
    VoidCallback? btnOkOnPress,
  }) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.bottomSlide,
      dialogBackgroundColor: Colors.white,
      title: title,
      desc: desc,
      btnOkText: btnOkText,
      btnOkColor: color,
      btnOkOnPress: btnOkOnPress ?? () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF20C65A);

    return Scaffold(
      appBar: AppBar(
        title: const Text("แก้ไขที่อยู่"),
        backgroundColor: primaryGreen,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _textField("รายละเอียดที่อยู่", addressDetailCtrl),
                  _textField("ตำบล/แขวง", subDistrictCtrl),
                  _textField("อำเภอ/เขต", districtCtrl),
                  _textField("จังหวัด", provinceCtrl),
                  _textField("รหัสไปรษณีย์", postalCtrl),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _updateAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "บันทึกการแก้ไข",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _deleteAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _textField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}
