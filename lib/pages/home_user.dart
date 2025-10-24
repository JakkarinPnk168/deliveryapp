import 'package:deliveryapp/pages/parcel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:deliveryapp/pages/profile.dart';
import 'package:deliveryapp/services/auth_service.dart';
import 'package:get/get.dart';
import 'package:deliveryapp/pages/parcel_create.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final _auth = AuthService();
  late Future<UserData> _future;

  @override
  void initState() {
    super.initState();
    _future = _auth.getMe();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _auth.getMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F6F5),
      body: SafeArea(
        child: FutureBuilder<UserData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text("ไม่พบข้อมูลผู้ใช้"));
            }

            final me = snapshot.data!;
            final phone = me.phone;
            final profileUrl = (me.profileImage.isNotEmpty)
                ? me.profileImage
                : null;

            return Column(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.cherryBombOne(
                            fontSize: 22,
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
                      Row(
                        children: [
                          Text(
                            phone,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: profileUrl != null
                                ? NetworkImage(profileUrl)
                                : const AssetImage("assets/images/user.png")
                                      as ImageProvider,
                            backgroundColor: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 🔹 Menu buttons (เหมือนเดิม)
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildMenuCard(
                        icon: Icons.local_shipping,
                        title: "ส่งพัสดุ",
                        subtitle: "สะดวกและง่าย",
                        color: Colors.orange,
                        onTap: () {
                          Get.to(
                            () => const ParcelCreatePage(),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                          );
                        },
                      ),

                      _buildMenuCard(
                        icon: Icons.bookmark,
                        title: "สถานะพัสดุ",
                        subtitle: "ติดตามสถานะได้ตลอด",
                        color: Colors.green,
                        onTap: () {
                          Get.to(
                            () => const ParcelPage(),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                          );
                        },
                      ),
                      _buildMenuCard(
                        icon: Icons.inventory,
                        title: "พัสดุของฉัน",
                        subtitle: "",
                        color: Colors.blue,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // 🔹 Bottom Navigation (เหมือนเดิม) + รีโหลดหลังกลับจากโปรไฟล์
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) async {
          if (index == 4) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
            // กลับมาหน้านี้แล้วรีโหลดข้อมูลเผื่อแก้โปรไฟล์
            if (mounted) _reload();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าหลัก"),
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: "พัสดุ"),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: "ส่งพัสดุ",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "รายการ"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "โปรไฟล์"),
        ],
      ),
    );
  }

  // 🔹 Card Builder (เหมือนเดิม)
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
