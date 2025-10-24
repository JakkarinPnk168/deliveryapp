import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:deliveryapp/controllers/parcel_detail_controller.dart';

class ParcelDetailPage extends StatefulWidget {
  final String orderId; // ✅ รับแค่ orderId แล้วให้ Controller โหลดข้อมูลเอง

  const ParcelDetailPage({super.key, required this.orderId});

  @override
  State<ParcelDetailPage> createState() => _ParcelDetailPageState();
}

class _ParcelDetailPageState extends State<ParcelDetailPage> {
  final mapController = MapController();
  final detailCtrl = Get.put(ParcelDetailController());

  @override
  void initState() {
    super.initState();
    detailCtrl.fetchParcelDetail(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F6F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A86B),
        title: const Text(
          'รายละเอียดพัสดุ',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Obx(() {
        if (detailCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (detailCtrl.hasError.value || detailCtrl.parcel.isEmpty) {
          return const Center(child: Text("⚠️ โหลดข้อมูลไม่สำเร็จ"));
        }

        final data = detailCtrl.parcel;
        final items = data['items'] ?? [];
        final status = data['status'] ?? 0;
        final sender = data['sender'] ?? {};
        final receiver = data['receiver'] ?? {};
        final rider = data['rider'] ?? {};
        final address = data['address'] ?? {};
        final position =
            detailCtrl.receiverPosition.value ??
            LatLng(
              (address['lat'] ?? 0).toDouble(),
              (address['lng'] ?? 0).toDouble(),
            );

        return ListView(
          children: [
            _buildMap(position),
            _buildStatusCard(status),
            _buildInfoCard(sender, receiver, rider, address),
            _buildItemList(items),
          ],
        );
      }),
    );
  }

  // 🗺️ ส่วนแผนที่
  Widget _buildMap(LatLng pos) {
    return SizedBox(
      height: 250,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(initialCenter: pos, initialZoom: 15.0),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=e4c23dbb20bc41449c12d826dcb5c74a',
            userAgentPackageName: 'com.example.deliveryapp',
          ),
          MarkerLayer(
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
          ),
        ],
      ),
    );
  }

  // 🚚 สถานะพัสดุ
  // 🚚 สถานะพัสดุ + รูปหลักฐาน
  Widget _buildStatusCard(dynamic status) {
    final text = detailCtrl.statusText(status);
    final color = Color(detailCtrl.statusColor(status));

    final proofImageUrl = detailCtrl.parcel['proofImageUrl'] ?? "";

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.local_shipping, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // ✅ แสดงรูปหลักฐานถ้ามี
          if (proofImageUrl.isNotEmpty)
            GestureDetector(
              onTap: () {
                // 🔍 เปิดดูภาพเต็มหน้าจอ
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.black,
                    insetPadding: const EdgeInsets.all(10),
                    child: InteractiveViewer(
                      child: Image.network(proofImageUrl),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  proofImageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 👥 ข้อมูลผู้ส่ง / ผู้รับ / Rider
  Widget _buildInfoCard(Map sender, Map receiver, Map rider, Map address) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ข้อมูลการจัดส่ง",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // 🔹 ผู้ส่ง
          _buildUserRow(Icons.send, "ผู้ส่ง", sender),

          // 🔹 ผู้รับ
          const SizedBox(height: 8),
          _buildUserRow(Icons.home, "ผู้รับ", receiver),

          // 🔹 Rider (ถ้ามี)
          if (rider.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildUserRow(Icons.delivery_dining, "ไรเดอร์", rider),
          ],

          const Divider(height: 20),

          // 🔹 ที่อยู่จัดส่ง
          Text(
            address['label'] ?? "ไม่พบชื่อสถานที่",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            address['address'] ?? "ไม่พบที่อยู่",
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(IconData icon, String role, Map data) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00A86B)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$role: ${data['name'] ?? '-'}",
                style: const TextStyle(fontSize: 14),
              ),
              if (data['phone'] != null)
                Text(
                  data['phone'],
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
            ],
          ),
        ),
        if (data['profileImage'] != null &&
            data['profileImage'].toString().isNotEmpty)
          CircleAvatar(
            backgroundImage: NetworkImage(data['profileImage']),
            radius: 20,
          ),
      ],
    );
  }

  // 🛒 รายการสินค้า
  Widget _buildItemList(List items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text("ไม่มีรายการสินค้า")),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "รายการสินค้า",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Divider(height: 1),
          ...items.map(
            (item) => ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['imageUrl'] ?? '',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              title: Text(item['productName'] ?? 'ไม่ระบุสินค้า'),
              subtitle: Text(
                " ",
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
