// lib/models/parcel_model.dart
import 'dart:io';

/// 📍 ที่อยู่ของผู้รับ
class ReceiverAddress {
  final String label;
  final String address;
  final double lat;
  final double lng;

  ReceiverAddress({
    required this.label,
    required this.address,
    required this.lat,
    required this.lng,
  });

  /// ✅ แปลงข้อมูลเป็น JSON เพื่อส่งไป backend
  Map<String, dynamic> toJson() => {
    "label": label,
    "address": address,
    "lat": lat,
    "lng": lng,
  };

  /// ✅ แปลงจาก JSON กลับมาเป็น Object (เช่นเมื่อดึงจาก Firestore)
  factory ReceiverAddress.fromJson(Map<String, dynamic> json) {
    return ReceiverAddress(
      label: json['label'] ?? '',
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }
}

/// 📦 รายละเอียดสินค้าที่แนบมากับพัสดุ
class ParcelItem {
  String productName;
  File? imageFile; // ✅ สำหรับอัปโหลดรูปแบบ multipart

  ParcelItem({required this.productName, this.imageFile});

  /// ✅ แปลงข้อมูลสินค้าเป็น JSON (ไม่รวมรูปภาพ)
  Map<String, dynamic> toJson() => {
    "productName": productName,
    // รูปภาพจะอัปโหลดแยก ไม่ส่งใน JSON
  };

  /// ✅ แปลงจาก JSON เป็น Object (เช่นเมื่อดึงจาก backend)
  factory ParcelItem.fromJson(Map<String, dynamic> json) {
    return ParcelItem(
      productName: json['productName'] ?? '',
      imageFile: null, // ดึงจาก backend จะไม่มีไฟล์แนบตรงนี้
    );
  }
}
