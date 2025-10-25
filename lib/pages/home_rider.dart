import 'dart:convert';
import 'package:deliveryapp/models/order_model.dart';
import 'package:deliveryapp/pages/profile_rider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:deliveryapp/services/auth_service.dart';
import 'package:deliveryapp/config/app_config.dart';

class RiderHomePage extends StatefulWidget {
  const RiderHomePage({super.key});

  @override
  State<RiderHomePage> createState() => _RiderHomePageState();
}

class _RiderHomePageState extends State<RiderHomePage> {
  final _auth = AuthService();
  late Future<UserData> _meFuture;
  late Future<List<Order>> _ordersFuture;
  bool showMyJobs = false; // ✅ toggle งานที่รอรับ / งานของฉัน

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
    try {
      // ✅ ดึง Header ที่มี Token (ใช้ method สาธารณะ)
      final headers = await _auth.getAuthHeader();

      // ✅ เลือกโหมด: mine = งานของฉัน, available = งานใหม่
      final mode = showMyJobs ? "mine" : "available";
      final url = Uri.parse(
        "${AppConfig.apiBaseUrl}/api/orders/rider?mode=$mode",
      );

      // ✅ เรียก API พร้อม timeout 10 วินาที
      final res = await http
          .get(url, headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception("การเชื่อมต่อหมดเวลา (Timeout)"),
          );

      // ✅ ตรวจสอบผลลัพธ์
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final dataList = body['data'] ?? [];

        // ตรวจสอบว่าคือ List หรือไม่
        if (dataList is List) {
          return List<Order>.from(dataList.map((e) => Order.fromJson(e)));
        } else {
          throw Exception("รูปแบบข้อมูลไม่ถูกต้องจากเซิร์ฟเวอร์");
        }
      } else if (res.statusCode == 401) {
        // ✅ token หมดอายุ → logout อัตโนมัติ
        await _auth.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Token หมดอายุ กรุณาเข้าสู่ระบบใหม่")),
          );
        }
        return [];
      } else {
        // ✅ กรณีอื่น ๆ
        final body = json.decode(res.body);
        final msg = body['message'] ?? "โหลดงานไม่สำเร็จ";
        throw Exception(msg);
      }
    } catch (e) {
      // ✅ Log & แจ้งเตือน error
      print("❌ [FetchOrders] Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
      }
      return [];
    }
  }

  // ✅ รับงาน + เปิดหน้าแผนที่
  Future<void> _acceptOrderAndNavigate(Order order) async {
    final headers = await _auth.getAuthHeader();
    final url = Uri.parse(
      "${AppConfig.apiBaseUrl}/api/orders/${order.orderId}/accept",
    );

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final res = await http.post(url, headers: headers);
      if (mounted) Navigator.of(context).pop();

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "รับงานสำเร็จ")),
        );

        _reload();
      } else {
        final data = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: ${data['message']}")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
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
                  child: Center(
                    child: RichText(
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
                  ),
                ),

                const SizedBox(height: 16),

                // Rider info
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

                // 🔄 toggle งาน
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        "งานใหม่",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: showMyJobs,
                        activeColor: Colors.green,
                        onChanged: (v) {
                          setState(() {
                            showMyJobs = v;
                            _ordersFuture = _fetchOrders();
                          });
                        },
                      ),
                      Text(
                        showMyJobs ? "งานของฉัน" : "รอรับงาน",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // List
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
                            "ยังไม่มีงานในขณะนี้",
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
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            o.addressDetail,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (o.status == 1)
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _acceptOrderAndNavigate(o),
                                          icon: const Icon(Icons.check),
                                          label: const Text("รับงาน"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade700,
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
