import 'package:flutter/material.dart';
import 'package:deliveryapp/pages/login.dart';
import 'package:deliveryapp/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 4; // ค่า default = โปรไฟล์
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

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F6F5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        title: const Text("โปรไฟล์", style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<UserData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("ไม่สามารถโหลดข้อมูลโปรไฟล์ได้"),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("ลองใหม่"),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _logout,
                      child: const Text("ออกจากระบบ"),
                    ),
                  ],
                ),
              ),
            );
          }

          final me = snapshot.data;
          if (me == null) {
            return const Center(child: Text("ไม่พบข้อมูลผู้ใช้"));
          }

          final name = me.name;
          final phone = me.phone;
          final profileUrl = me.profileImage.isNotEmpty
              ? me.profileImage
              : null;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 60,
                  backgroundImage: profileUrl != null
                      ? NetworkImage(profileUrl)
                      : const AssetImage("assets/images/user.png")
                            as ImageProvider,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  phone,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // ปุ่มแก้ไข
                ElevatedButton.icon(
                  onPressed: () async {
                    final updated = await Navigator.pushNamed(
                      context,
                      '/editProfile',
                    );
                    if (updated == true) _reload();
                  },
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                  label: const Text(
                    "แก้ไข",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ปุ่มจัดการที่อยู่
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.white,
                  leading: const Icon(Icons.location_on, color: Colors.green),
                  title: const Text("จัดการที่อยู่"),
                  onTap: () {},
                ),
                const Spacer(),

                // ปุ่มออกจากระบบ
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "ออกจากระบบ",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // 🔹 Bottom Navigation Bar (เหมือนเดิม)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) async {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacementNamed(context, "/homeUser");
          } else if (index == 4) {
            // หน้านี้
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
}
