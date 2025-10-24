import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../services/auth_service.dart';

class RiderMapController extends ChangeNotifier {
  final Order order;
  final AuthService authService;

  RiderMapController({required this.order, required this.authService});

  // --- 🔹 State Variables ---
  LatLng? currentPosition;
  List<LatLng> routePoints = [];
  int currentStatus = 2; // เริ่มที่ "กำลังไปรับ"

  bool loadingLocation = true;
  bool loadingRoute = false;
  bool updatingStatus = false;
  String? errorMessage;

  // --- 🔹 Initialization ---
  Future<void> initialize() async {
    currentStatus = order.status;
    await getCurrentLocation();
    if (currentPosition != null) {
      await fetchRoute();
    }
  }

  // --- 🔹 ดึงตำแหน่งปัจจุบัน ---
  Future<void> getCurrentLocation() async {
    try {
      loadingLocation = true;
      errorMessage = null;
      notifyListeners();

      // ตรวจสอบ Location Service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('กรุณาเปิด Location Service');
      }

      // ขอ Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('ไม่ได้รับอนุญาตเข้าถึงตำแหน่ง');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('กรุณาเปิดการอนุญาตตำแหน่งในการตั้งค่า');
      }

      // ดึงตำแหน่ง
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentPosition = LatLng(position.latitude, position.longitude);
      loadingLocation = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      loadingLocation = false;
      notifyListeners();
    }
  }

  // --- 🔹 ดึงเส้นทางจาก OSRM ---
  Future<void> fetchRoute() async {
    if (currentPosition == null) return;

    try {
      loadingRoute = true;
      errorMessage = null;
      notifyListeners();

      final start = currentPosition!;
      final end = LatLng(order.lat, order.lng);

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final coordinates =
              data['routes'][0]['geometry']['coordinates'] as List;

          routePoints = coordinates
              .map((coord) => LatLng(coord[1], coord[0]))
              .toList();
        } else {
          throw Exception('ไม่พบเส้นทาง');
        }
      } else {
        throw Exception('ไม่สามารถดึงเส้นทางได้');
      }

      loadingRoute = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'เกิดข้อผิดพลาด: $e';
      loadingRoute = false;
      notifyListeners();
    }
  }

  // --- 🔹 อัปเดตสถานะงาน ---
  Future<bool> updateStatus(int newStatus) async {
    if (updatingStatus) return false;

    try {
      updatingStatus = true;
      errorMessage = null;
      notifyListeners();

      final token = await authService.token;
      if (token == null) throw Exception('ไม่พบ Token');

      final url = Uri.parse(
        'http://192.168.1.105:3000/api/orders/${order.orderId}/status',
      );

      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': newStatus}),
      );

      if (res.statusCode == 200) {
        currentStatus = newStatus;
        updatingStatus = false;
        notifyListeners();
        return true;
      } else {
        final data = json.decode(res.body);
        throw Exception(data['message'] ?? 'อัปเดตสถานะไม่สำเร็จ');
      }
    } catch (e) {
      errorMessage = 'อัปเดตสถานะไม่สำเร็จ: $e';
      updatingStatus = false;
      notifyListeners();
      return false;
    }
  }

  // --- 🔹 รีเฟรชตำแหน่ง ---
  Future<void> refreshLocation() async {
    await getCurrentLocation();
    if (currentPosition != null) {
      await fetchRoute();
    }
  }

  // --- 🔹 Helper Methods ---
  String getStatusText(int status) {
    switch (status) {
      case 1:
        return 'รอรับงาน';
      case 2:
        return 'กำลังไปรับ';
      case 3:
        return 'กำลังจัดส่ง';
      case 4:
        return 'ส่งสำเร็จ';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.deepOrange;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // --- 🔹 คำนวณระยะทางไปจุดหมาย (เมตร) ---
  double? getDistanceToDestination() {
    if (currentPosition == null) return null;

    return Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      order.lat,
      order.lng,
    );
  }

  // --- 🔹 แปลงระยะทางเป็นข้อความ ---
  String getDistanceText() {
    final distance = getDistanceToDestination();
    if (distance == null) return 'กำลังคำนวณ...';

    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} ม.';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} กม.';
    }
  }

  // --- 🔹 คำนวณระยะทางจากพิกัดใดก็ได้ ---
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
