import 'package:deliveryapp/pages/address_edit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../controllers/address_add_controller.dart';
import '../services/api_service.dart';
import '../models/address_model.dart';

class AddressAddPage extends StatefulWidget {
  const AddressAddPage({super.key});

  @override
  State<AddressAddPage> createState() => _AddressAddPageState();
}

class _AddressAddPageState extends State<AddressAddPage> {
  final mapController = MapController();
  final storage = const FlutterSecureStorage();
  late final AddressAddController controller;
  List<AddressModel> savedAddresses = [];
  var showForm = false.obs;

  Future<String?> _token() async => await storage.read(key: 'token');

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      AddressAddController(api: ApiService(), tokenProvider: _token),
    );
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    final token = await _token();
    if (token != null) {
      try {
        final addresses = await controller.api.getAddresses(token);
        setState(() => savedAddresses = addresses);
      } catch (e) {
        debugPrint('⚠️ โหลดที่อยู่ไม่สำเร็จ: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF20C65A);
    const lightBackground = Color(0xFFF2FAF5);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: const Text(
          'เพิ่มที่อยู่',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMapSection(),
            _buildSelectedAddressBox(),
            _buildActionButtons(context, primaryGreen),
            Obx(() => showForm.value ? _buildAddressForm() : const SizedBox()),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'ที่อยู่ทั้งหมด',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            _buildSavedList(primaryGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    final latLng =
        controller.selectedLocation.value ?? LatLng(16.1809, 103.3007);
    return SizedBox(
      height: 250,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: latLng,
          initialZoom: 15.0,
          onTap: (tapPosition, point) => controller.setSelected(point),
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=e4c23dbb20bc41449c12d826dcb5c74a',
            userAgentPackageName: 'com.example.deliveryapp',
            maxNativeZoom: 19,
          ),
          Obx(() {
            final pos = controller.selectedLocation.value;
            return pos == null
                ? const SizedBox()
                : MarkerLayer(
                    markers: [
                      Marker(
                        point: pos,
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.location_on,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  );
          }),
        ],
      ),
    );
  }

  Widget _buildSelectedAddressBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on, color: Colors.red, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() {
              final pos = controller.selectedLocation.value;
              return Text(
                pos == null
                    ? 'ยังไม่ได้เลือกตำแหน่ง (สามารถกรอกที่อยู่เองได้ด้านล่าง)'
                    : 'พิกัด (${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)})',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Color primaryGreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final ok = await controller.submit();
                if (ok != null) {
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.noHeader,
                    animType: AnimType.bottomSlide,
                    dialogBackgroundColor: Colors.white,
                    title: 'เพิ่มที่อยู่สำเร็จ ✅',
                    desc: 'ระบบได้บันทึกที่อยู่ของคุณเรียบร้อยแล้ว',
                    btnOkText: 'ตกลง',
                    btnOkColor: const Color(0xFF20C65A),
                    btnOkOnPress: () async {
                      await _loadSavedAddresses();
                    },
                  ).show();
                } else {
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.noHeader,
                    animType: AnimType.bottomSlide,
                    dialogBackgroundColor: Colors.white,
                    title: 'เกิดข้อผิดพลาด ❌',
                    desc: controller.errorMessage.value.isEmpty
                        ? 'ไม่สามารถบันทึกที่อยู่ได้'
                        : controller.errorMessage.value,
                    btnOkText: 'ปิด',
                    btnOkColor: Colors.red,
                    btnOkOnPress: () {},
                  ).show();
                }
              },
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'บันทึกตำแหน่งนี้',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => showForm.value = !showForm.value,
            icon: Icon(
              showForm.value ? Icons.close : Icons.add_location_alt,
              color: Colors.white,
            ),
            label: Text(
              showForm.value ? 'ยกเลิก' : 'เพิ่มที่อยู่ใหม่',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _textField("รายละเอียดที่อยู่", controller.addressDetailController),
          _textField("ตำบล/แขวง", controller.subDistrictController),
          _textField("อำเภอ/เขต", controller.districtController),
          _textField("จังหวัด", controller.provinceController),
          _textField("รหัสไปรษณีย์", controller.postalCodeController),
        ],
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
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

  Widget _buildSavedList(Color primaryGreen) {
    if (savedAddresses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text('ยังไม่มีที่อยู่ที่บันทึกไว้'),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: savedAddresses.map((addr) {
          final fullAddress = [
            if (addr.addressLine.isNotEmpty) addr.addressLine,
            if (addr.subDistrict.isNotEmpty) "ต.${addr.subDistrict}",
            if (addr.district.isNotEmpty) "อ.${addr.district}",
            if (addr.province.isNotEmpty) "จ.${addr.province}",
            if (addr.postalCode.isNotEmpty) addr.postalCode,
          ].where((e) => e.isNotEmpty).join(", ");

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addr.addressLine.isNotEmpty
                              ? addr.addressLine
                              : "ที่อยู่ไม่ระบุ",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fullAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Get.to(
                        () => AddressEditPage(addressId: addr.id),
                      );
                      if (result == true) {
                        await _loadSavedAddresses();
                      }
                    },
                    child: Text(
                      'แก้ไข',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),
            ],
          );
        }).toList(),
      ),
    );
  }
}
