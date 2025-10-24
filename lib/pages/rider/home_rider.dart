import 'dart:convert';
import 'package:deliveryapp/models/order_model.dart';
import 'package:deliveryapp/pages/rider/profile_rider.dart';
import 'package:deliveryapp/pages/rider/rider_map_page.dart'; // ✅ เพิ่ม import
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:deliveryapp/services/auth_service.dart';

class RiderHomePage extends StatefulWidget {
  const RiderHomePage({super.key});

  @override
  State<RiderHomePage> createState() => _RiderHomePageState();
}

class _RiderHomePageState extends State<RiderHomePage> {
  final _auth = AuthService();
  late Future<UserData> _meFuture;
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _meFuture = _auth.getMe();
    _ordersFuture = _fetchOrders();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _meFuture = _auth.getMe();
      _ordersFuture = _fetchOrders();
    });
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return "รอรับงาน";
      case 2:
        return "กำลังไปรับ";
      case 3:
        return "กำลังจัดส่ง";
      case 4:
        return "ส่งสำเร็จ";
      default:
        return "ไม่ทราบสถานะ";
    }
  }

  Future<List<Order>> _fetchOrders() async {
    final token = await _auth.token;
    if (token == null) return [];

    final url = Uri.parse("http://192.168.1.105:3000/api/orders/rider");
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data['data'] != null) {
        final orders = (data['data'] as List)
            .map((e) => Order.fromJson(e))
            .toList();
        return orders;
      }
      return [];
    } else {
      throw Exception("Failed to fetch orders: ${res.body}");
    }
  }

  // ✅ ฟังก์ชันรับงานและไปหน้าแผนที่
  Future<void> _acceptOrderAndNavigate(Order order) async {
    final token = await _auth.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("กรุณาเข้าสู่ระบบใหม่")));
      }
      return;
    }

    final url = Uri.parse(
      "http://192.168.1.105:3000/api/orders/${order.orderId}/accept",
    );

    try {
      // แสดง Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final res = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      // ปิด Loading
      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;

      if (res.statusCode == 200) {
        // ✅ รับงานสำเร็จ → ไปหน้าแผนที่
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RiderMapPage(order: order)),
        ).then((_) {
          // เมื่อกลับมา → รีโหลดรายการ
          if (mounted) _reload();
        });
      } else {
        final data = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: ${data['message']}")),
        );
      }
    } catch (e) {
      // ปิด Loading
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F6F5),
      body: SafeArea(
        child: FutureBuilder<UserData>(
          future: _meFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text("ไม่พบข้อมูล Rider"));
            }

            final me = snapshot.data!;
            final name = me.name;
            final phone = me.phone;
            final profileUrl = me.profileImage.isNotEmpty
                ? me.profileImage
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF64DD17)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.cherryBombOne(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                          children: const [
                            TextSpan(
                              text: "Lightning ",
                              style: TextStyle(color: Colors.yellow),
                            ),
                            TextSpan(
                              text: "BOLT",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Rider Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileRiderPage(),
                        ),
                      );
                      if (mounted) _reload();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: profileUrl != null
                                ? NetworkImage(profileUrl)
                                : const AssetImage("assets/images/user.png")
                                      as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                phone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // หัวข้อ
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "งานใหม่",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // รายการงาน
                Expanded(
                  child: FutureBuilder<List<Order>>(
                    future: _ordersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("เกิดข้อผิดพลาด: ${snapshot.error}"),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _reload,
                                child: const Text("ลองอีกครั้ง"),
                              ),
                            ],
                          ),
                        );
                      }
                      final orders = snapshot.data ?? [];
                      if (orders.isEmpty) {
                        return const Center(
                          child: Text(
                            "ยังไม่มีงานใหม่เข้ามา",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final o = orders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // รูปสินค้า + ชื่อ
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            o.imageUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                o.productName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                o.addressLabel,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const Divider(height: 20),

                                    // ที่อยู่จัดส่ง
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                o.addressDetail,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              // แสดงพิกัด
                                              Text(
                                                '📍 ${o.lat.toStringAsFixed(6)}, ${o.lng.toStringAsFixed(6)}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // ปุ่มรับงาน
                                    if (o.status == 1)
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _acceptOrderAndNavigate(
                                                o,
                                              ), // ✅ เปลี่ยนตรงนี้
                                          icon: const Icon(Icons.check_circle),
                                          label: const Text("รับงาน"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          "สถานะ: ${_getStatusText(o.status)}",
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
