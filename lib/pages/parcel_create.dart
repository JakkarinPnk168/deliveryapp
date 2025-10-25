import 'dart:io';
import 'package:deliveryapp/controllers/parcel_create_controller.dart';
import 'package:deliveryapp/controllers/parcel_controller.dart';
import 'package:deliveryapp/models/parcel_item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MapControllerX extends GetxController {
  var selectedLocation = Rxn<LatLng>();
  void setSelected(LatLng point) => selectedLocation.value = point;
}

class ParcelCreatePage extends StatefulWidget {
  const ParcelCreatePage({super.key});

  @override
  State<ParcelCreatePage> createState() => _ParcelCreatePageState();
}

class _ParcelCreatePageState extends State<ParcelCreatePage> {
  final _controller = ParcelCreateController();
  final mapController = MapController();
  final mapX = Get.put(MapControllerX());
  final storage = const FlutterSecureStorage();
  final _phoneController = TextEditingController();

  List<Map<String, dynamic>> allContacts = [];
  Map<String, dynamic>? selectedReceiver;
  String? receiverId;
  List<Map<String, dynamic>> receiverAddresses = [];
  ReceiverAddress? selectedAddress;
  bool useMap = false;
  bool loading = false;

  final List<ParcelItem> _items = [];
  File? _proofImage; // ✅ เก็บรูปหลักฐาน

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ParcelController>()) {
      Get.put(ParcelController());
    }
    _loadAllContacts();
  }

  // ✅ โหลดรายชื่อผู้ใช้และไรเดอร์ทั้งหมด
  Future<void> _loadAllContacts() async {
    try {
      setState(() => loading = true);
      final list = await _controller.getAllContacts();

      // ✅ normalize ให้ทุก contact มีทั้ง id และ userId
      final normalized = list.map((u) {
        final uid = u['id'] ?? u['userId'];
        return {
          ...u,
          'id': uid,
          'userId': uid,
          'name': u['name'] ?? "ไม่ระบุชื่อ",
          'phone': u['phone'] ?? "-",
          'profileImage': u['profileImage'] ?? "",
          'role': u['role'] ?? "user",
        };
      }).toList();

      setState(() => allContacts = normalized);
      print("✅ โหลดรายชื่อผู้ใช้สำเร็จ (${normalized.length}) รายการ");
    } catch (e) {
      debugPrint("🔥 โหลดรายชื่อผู้ใช้ล้มเหลว: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  // ✅ ค้นหาผู้รับด้วยเบอร์โทร
  Future<void> _searchReceiverByPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ กรุณากรอกเบอร์โทรก่อนค้นหา')),
      );
      return;
    }

    try {
      setState(() => loading = true);
      final res = await _controller.searchReceiver(phone);
      setState(() => loading = false);

      if (res != null && res['success'] == true) {
        final user = res['data'];

        // ✅ reset state เก่า ป้องกันซ้ำ
        setState(() {
          print("📞 เรียก _setNewReceiver() จากการค้นหาเบอร์โทร");
          selectedReceiver = null;
          receiverAddresses = [];
          receiverId = null;
        });

        // ✅ ใช้ _setNewReceiver เพื่อให้ format เดียวกันเสมอ
        _setNewReceiver(user);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ พบผู้รับในระบบ')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ ไม่พบผู้รับในระบบ')));
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint("🔥 Error _searchReceiverByPhone: $e");
    }
  }

  // ✅ ตั้งค่าผู้รับใหม่จากข้อมูลที่เลือกหรือค้นหา
  void _setNewReceiver(Map<String, dynamic> user) {
    final uid = (user['userId'] ?? user['id'])?.toString().trim();
    if (uid == null || uid.isEmpty) {
      print("⚠️ userId ของผู้รับว่างหรือไม่ถูกต้อง: $user");
      return;
    }

    setState(() {
      selectedReceiver = {
        'id': uid,
        'userId': uid,
        'name': user['name'] ?? "ไม่ระบุชื่อ",
        'phone': user['phone'] ?? "-",
        'profileImage': user['profileImage'] ?? "",
        'role': user['role'] ?? 'user',
        'addresses': user['addresses'] ?? [],
      };
      receiverId = uid;
      receiverAddresses = List<Map<String, dynamic>>.from(
        user['addresses'] ?? [],
      );
    });

    print("👤 ตั้งค่าผู้รับใหม่แล้ว:");
    print("   ↳ id       = $receiverId");
    print("   ↳ name     = ${selectedReceiver!['name']}");
    print("   ↳ phone    = ${selectedReceiver!['phone']}");
    print("   ↳ addresses= ${receiverAddresses.length} รายการ");
  }

  // ✅ โหลดที่อยู่ของผู้รับจากเบอร์โทร
  Future<void> _loadReceiverAddresses(String phone) async {
    try {
      setState(() => loading = true);
      final res = await _controller.searchReceiver(phone);
      setState(() => loading = false);

      if (res != null && res['success'] == true) {
        final user = res['data'];
        final addresses = List<Map<String, dynamic>>.from(
          user['addresses'] ?? [],
        );

        setState(() {
          receiverId = user['userId'];
          receiverAddresses = addresses;
        });

        print(
          "📍 โหลดที่อยู่ผู้รับ ${addresses.length} รายการ สำหรับ ${user['name']}",
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ ไม่พบที่อยู่ผู้รับในระบบ')),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint("🔥 Error _loadReceiverAddresses: $e");
    }
  }

  // ✅ เพิ่มสินค้าใหม่
  void _addItem() {
    setState(() => _items.add(ParcelItem(productName: "", imageFile: null)));
    print("🛒 เพิ่มสินค้าใหม่ (${_items.length}) ชิ้น");
  }

  // ✅ เลือกรูปสินค้า
  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _items[index] = ParcelItem(
          productName: _items[index].productName,
          imageFile: File(picked.path),
        );
      });
      print("📸 เพิ่มรูปสินค้า ${picked.path}");
    }
  }

  // ✅ ถ่ายรูปหลักฐาน
  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _proofImage = File(picked.path));
      print("📷 ถ่ายรูปหลักฐาน ${picked.path}");
    }
  }

  // ✅ ส่งพัสดุ
  Future<void> _submitParcel() async {
    try {
      final senderId = await storage.read(key: "userId");
      print("🚀 เริ่มส่งพัสดุ");
      print("📦 senderId  = $senderId");
      print("📦 receiverId = $receiverId");

      if (senderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ กรุณาเข้าสู่ระบบก่อนส่งพัสดุ')),
        );
        return;
      }

      if (receiverId == null || _items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ กรุณากรอกข้อมูลให้ครบ')),
        );
        return;
      }

      // 🚫 ป้องกันผู้ส่งและผู้รับเป็นคนเดียวกัน
      if (receiverId == senderId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ ผู้ส่งและผู้รับต้องไม่เป็นคนเดียวกัน'),
          ),
        );
        print("⚠️ ผู้ส่งและผู้รับเป็น ID เดียวกัน");
        return;
      }

      // ✅ ถ้าไม่ได้ถ่ายรูปหลักฐาน ห้ามสร้างพัสดุ
      if (_proofImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ กรุณาถ่ายรูปหลักฐานก่อนสร้างพัสดุ')),
        );
        return;
      }

      late final ReceiverAddress address;
      if (useMap) {
        final pos = mapX.selectedLocation.value;
        if (pos == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ กรุณาเลือกพิกัดบนแผนที่')),
          );
          return;
        }
        address = ReceiverAddress(
          label: "พิกัดที่เลือก",
          address:
              "ละติจูด ${pos.latitude.toStringAsFixed(6)}, ลองจิจูด ${pos.longitude.toStringAsFixed(6)}",
          lat: pos.latitude,
          lng: pos.longitude,
        );
      } else {
        if (selectedAddress == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ กรุณาเลือกที่อยู่จากรายการ')),
          );
          return;
        }
        address = selectedAddress!;
      }

      print("📍 ที่อยู่ผู้รับ: ${address.address}");

      setState(() => loading = true);
      final result = await _controller.createParcel(
        senderId: senderId,
        receiverId: receiverId!,
        receiverAddress: address,
        items: _items,
        proofImage: _proofImage, // ✅ ส่งรูปหลักฐานไปด้วย
      );

      setState(() => loading = false);

      print("📨 สร้างพัสดุผลลัพธ์: $result");

      if (result['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ สร้างพัสดุสำเร็จ')));

        final senderCtrl = Get.find<ParcelController>();
        await senderCtrl.fetchSenderParcels(senderId);

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ สร้างพัสดุไม่สำเร็จ: ${result['message']}'),
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint("🔥 Error submit: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultLatLng = const LatLng(16.1873, 103.3021);
    return Scaffold(
      backgroundColor: const Color(0xFFE9F6F5),
      appBar: AppBar(
        title: const Text(
          "สร้างพัสดุส่งสินค้า",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔍 ค้นหาผู้รับด้วยเบอร์โทร
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: "ค้นหาผู้รับด้วยหมายเลขโทรศัพท์",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.green),
                        onPressed: _searchReceiverByPhone,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // 🔽 Dropdown รายชื่อทั้งหมด (ป้องกัน crash)
                  DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true,
                    value: selectedReceiver == null
                        ? null
                        : allContacts.firstWhere(
                            (c) => c['userId'] == selectedReceiver!['userId'],
                            orElse: () =>
                                <String, dynamic>{}, // ✅ map ว่างแทน null
                          ),
                    decoration: InputDecoration(
                      labelText: "หรือเลือกผู้รับจากรายชื่อในระบบ",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: allContacts.map((contact) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: contact,
                        child: Text("${contact['name']} (${contact['phone']})"),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null && value.isNotEmpty) {
                        _setNewReceiver(value);
                        await _loadReceiverAddresses(value['phone']);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // 🧾 การ์ดผู้รับ
                  if (selectedReceiver != null)
                    Card(
                      color: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  (selectedReceiver!['profileImage'] ?? '')
                                      .isNotEmpty
                                  ? NetworkImage(
                                      selectedReceiver!['profileImage'],
                                    )
                                  : null,
                              child:
                                  (selectedReceiver!['profileImage'] ?? '')
                                      .isEmpty
                                  ? const Icon(Icons.person, size: 28)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedReceiver!['name'] ?? 'ไม่ระบุชื่อ',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  selectedReceiver!['phone'] ?? '-',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // 🏠 ส่วนเลือกที่อยู่
                  if (receiverAddresses.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "เลือกวิธีระบุที่อยู่ผู้รับ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        RadioListTile<bool>(
                          value: false,
                          groupValue: useMap,
                          onChanged: (v) => setState(() => useMap = v!),
                          title: const Text("เลือกจากรายการที่อยู่"),
                        ),
                        RadioListTile<bool>(
                          value: true,
                          groupValue: useMap,
                          onChanged: (v) => setState(() => useMap = v!),
                          title: const Text("เลือกจากแผนที่"),
                        ),
                        if (!useMap)
                          DropdownButtonFormField<Map<String, dynamic>>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: "เลือกที่อยู่ที่ต้องการจัดส่ง",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: receiverAddresses.map((a) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: a,
                                child: Text(
                                  a['address_detail'] ?? "ไม่ระบุที่อยู่",
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedAddress = ReceiverAddress(
                                    label: val['label'] ?? 'ที่อยู่ในระบบ',
                                    address: val['address_detail'] ?? '',
                                    lat: (val['gps_latitude'] ?? 0).toDouble(),
                                    lng: (val['gps_longitude'] ?? 0).toDouble(),
                                  );
                                  mapX.setSelected(
                                    LatLng(
                                      selectedAddress!.lat,
                                      selectedAddress!.lng,
                                    ),
                                  );
                                });
                              }
                            },
                          ),
                        if (useMap)
                          Container(
                            height: 250,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FlutterMap(
                              mapController: mapController,
                              options: MapOptions(
                                initialCenter: defaultLatLng,
                                initialZoom: 15.0,
                                onTap: (tapPosition, point) {
                                  mapX.setSelected(point);
                                  setState(() {
                                    selectedAddress = ReceiverAddress(
                                      label: "พิกัดที่เลือก",
                                      address:
                                          "ละติจูด ${point.latitude.toStringAsFixed(6)}, ลองจิจูด ${point.longitude.toStringAsFixed(6)}",
                                      lat: point.latitude,
                                      lng: point.longitude,
                                    );
                                  });
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=e4c23dbb20bc41449c12d826dcb5c74a',
                                  userAgentPackageName:
                                      'com.example.deliveryapp',
                                ),
                                Obx(() {
                                  final pos = mapX.selectedLocation.value;
                                  return pos == null
                                      ? const SizedBox()
                                      : MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: pos,
                                              width: 40,
                                              height: 40,
                                              child: const Icon(
                                                Icons.location_on,
                                                color: Colors.red,
                                                size: 40,
                                              ),
                                            ),
                                          ],
                                        );
                                }),
                              ],
                            ),
                          ),
                      ],
                    ),

                  const SizedBox(height: 20),
                  _buildItemList(),
                  const SizedBox(height: 20),
                  _buildProofUpload(),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitParcel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "บันทึก",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ✅ รายการสินค้า
  Widget _buildItemList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "รายละเอียดสินค้า",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ..._items.map((item) {
            final index = _items.indexOf(item);
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: item.productName,
                      decoration: const InputDecoration(
                        labelText: "ชื่อสินค้า",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        _items[index] = ParcelItem(
                          productName: val,
                          imageFile: item.imageFile,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: item.imageFile != null
                              ? Image.file(
                                  item.imageFile!,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : const Text(
                                  "ยังไม่ได้เลือกรูป",
                                  style: TextStyle(color: Colors.grey),
                                ),
                        ),
                        IconButton(
                          onPressed: () => _pickImage(index),
                          icon: const Icon(Icons.upload, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          Center(
            child: OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text("เพิ่มสินค้า"),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ อัปโหลดรูปหลักฐาน
  Widget _buildProofUpload() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "รูปหลักฐานการส่ง",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _proofImage != null
              ? Image.file(_proofImage!, height: 150, fit: BoxFit.cover)
              : const Text(
                  "ยังไม่ได้เลือกรูป",
                  style: TextStyle(color: Colors.grey),
                ),
          const SizedBox(height: 8),
          Center(
            child: OutlinedButton.icon(
              onPressed: _pickProofImage,
              icon: const Icon(Icons.camera_alt, color: Colors.green),
              label: const Text("ถ่ายรูปหลักฐาน"),
            ),
          ),
        ],
      ),
    );
  }
}
