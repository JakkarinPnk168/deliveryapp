import 'package:deliveryapp/pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:deliveryapp/services/auth_service.dart';

class RiderHomePage extends StatefulWidget {
  const RiderHomePage({super.key});

  @override
  State<RiderHomePage> createState() => _RiderHomePageState();
}

class _RiderHomePageState extends State<RiderHomePage> {
  final _auth = AuthService();
  late Future<UserData> _meFuture;

  @override
  void initState() {
    super.initState();
    _meFuture = _auth.getMe();
  }

  Future<void> _reload() async {
    setState(() {
      _meFuture = _auth.getMe();
    });
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
                // 🔹 Header (เหมือนเดิม)
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

                // 🔹 Rider Info (กดไปหน้าโปรไฟล์)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
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

                // 🔹 หัวข้อ (ไว้คง UI เดิม)
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

                // 🔹 พื้นที่รายการงาน (ยังไม่ทำระบบ — แสดงข้อความว่างไว้ก่อน)
                const Expanded(
                  child: Center(
                    child: Text(
                      "ยังไม่มีงานใหม่เข้ามา",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
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
