import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:deliveryapp/controllers/parcel_controller.dart';
import 'package:deliveryapp/pages/parcel_detail.dart'; // ✅ เพิ่ม import

class ParcelPage extends StatefulWidget {
  const ParcelPage({super.key});

  @override
  State<ParcelPage> createState() => _ParcelPageState();
}

class _ParcelPageState extends State<ParcelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final parcelCtrl = Get.put(ParcelController());
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await storage.read(key: 'userId');
    if (userId == null) return;
    await parcelCtrl.fetchSenderParcels(userId);
    await parcelCtrl.fetchReceiverParcels(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F6F5),
      appBar: AppBar(
        title: const Text('พัสดุ', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00A86B),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "ส่งพัสดุ"),
            Tab(text: "รับพัสดุ"),
          ],
        ),
      ),
      body: Obx(() {
        if (parcelCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (parcelCtrl.hasError.value) {
          return const Center(child: Text("⚠️ โหลดข้อมูลล้มเหลว"));
        }

        return TabBarView(
          controller: _tabController,
          children: [_buildSenderTab(), _buildReceiverTab()],
        );
      }),
    );
  }

  // 📦 TAB: ผู้ส่ง
  Widget _buildSenderTab() {
    final parcels = parcelCtrl.senderParcels;
    if (parcels.isEmpty) {
      return const Center(child: Text("ไม่มีข้อมูลพัสดุที่ส่ง"));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: parcels.length,
        itemBuilder: (context, index) {
          final order = parcels[index];
          return _buildParcelCard(order);
        },
      ),
    );
  }

  // 📦 TAB: ผู้รับ
  Widget _buildReceiverTab() {
    final parcels = parcelCtrl.receiverParcels;
    if (parcels.isEmpty) {
      return const Center(child: Text("ไม่มีพัสดุที่รอรับ"));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: parcels.length,
        itemBuilder: (context, index) {
          final order = parcels[index];
          return _buildParcelCard(order);
        },
      ),
    );
  }

  // 🔹 ใช้ร่วมกันทั้งผู้ส่งและผู้รับ
  Widget _buildParcelCard(Map<String, dynamic> order) {
    final items = order['items'] ?? [];
    final status = order['status'] ?? 0;
    final address = order['address'] ?? {};

    String productList = "ไม่ระบุสินค้า";
    String imageUrl = "";
    int itemCount = 0;

    if (items is List && items.isNotEmpty) {
      productList = items.map((i) => i['productName'] ?? "").join(", ");
      imageUrl = items.first['imageUrl'] ?? "";
      itemCount = items.length;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.inventory_2, color: Colors.grey),
                ),
        ),
        title: Text(
          productList,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("จำนวนสินค้า: $itemCount รายการ"),
            if (address['label'] != null) Text("ที่อยู่: ${address['label']}"),
            if (address['address'] != null)
              Text(
                address['address'],
                style: const TextStyle(fontSize: 13, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              _statusText(status),
              style: TextStyle(color: _statusColor(status)),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            // ✅ ไปหน้า ParcelDetailPage ด้วย GetX
            final orderId = order['orderId'];
            if (orderId != null) {
              Get.to(() => ParcelDetailPage(orderId: orderId));
            } else {
              Get.snackbar(
                "ข้อผิดพลาด",
                "ไม่พบรหัสพัสดุ",
                backgroundColor: Colors.red.shade100,
              );
            }
          },
        ),
      ),
    );
  }

  // 🏷️ ฟังก์ชันสถานะ
  String _statusText(int s) {
    switch (s) {
      case 1:
        return "รอไรเดอร์รับสินค้า";
      case 2:
        return "กำลังจัดส่ง";
      case 3:
        return "จัดส่งสำเร็จ";
      default:
        return "รอการยืนยัน";
    }
  }

  Color _statusColor(int s) {
    switch (s) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
