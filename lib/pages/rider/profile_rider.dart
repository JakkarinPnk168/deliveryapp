import 'package:flutter/material.dart';
import 'package:deliveryapp/pages/login.dart';
import 'package:deliveryapp/services/auth_service.dart';

class ProfileRiderPage extends StatefulWidget {
  const ProfileRiderPage({super.key});

  @override
  State<ProfileRiderPage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfileRiderPage> {
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

          final profileUrl = (me.profileImage ?? '').isNotEmpty
              ? me.profileImage
              : null;
          final vehicleUrl = (me.vehicleImage ?? '').isNotEmpty
              ? me.vehicleImage
              : null;
          final vehiclePlate = (me.vehiclePlate ?? '').isNotEmpty
              ? me.vehiclePlate
              : "ยังไม่ได้ระบุ";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // รูปโปรไฟล์
                CircleAvatar(
                  radius: 60,
                  backgroundImage: profileUrl != null
                      ? NetworkImage(profileUrl)
                      : const AssetImage("assets/images/user.png")
                            as ImageProvider,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),

                // ชื่อและเบอร์
                Text(
                  me.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  me.phone,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // ปุ่มแก้ไขโปรไฟล์
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

                // ข้อมูลรถ
                // ข้อมูลรถ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "ข้อมูลรถของคุณ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // รูปและทะเบียนอยู่ใน Row
                      Row(
                        children: [
                          // รูปรถ
                          Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                              image: vehicleUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(vehicleUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: vehicleUrl == null
                                ? const Center(
                                    child: Text(
                                      "ยังไม่มีรูปรถ",
                                      style: TextStyle(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),

                          // ข้อมูลทะเบียน
                          Expanded(
                            child: Text(
                              "ทะเบียนรถ: $vehiclePlate",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ปุ่มแก้ไขรถอยู่ตรงกลาง
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("ยังไม่ทำหน้าแก้ไขข้อมูลรถ"),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("แก้ไขข้อมูลรถ"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),

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
    );
  }
}
