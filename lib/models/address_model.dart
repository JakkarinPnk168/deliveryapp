class AddressModel {
  final String id; // สร้างบน backend
  final String label; // บ้าน/ที่ทำงาน/อื่นๆ
  final String recipientName; // ชื่อผู้รับ
  final String phone;
  final String addressLine; // บ้านเลขที่ ซอย ถนน
  final String subDistrict; // ตำบล/แขวง
  final String district; // อำเภอ/เขต
  final String province;
  final String postalCode;
  final double lat;
  final double lng;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.postalCode,
    required this.lat,
    required this.lng,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> j) => AddressModel(
    id: j['id'] ?? j['addressId'] ?? '',
    label: j['label'] ?? '',
    recipientName: j['recipientName'] ?? '',
    phone: j['phone'] ?? '',
    addressLine: j['addressLine'] ?? '',
    subDistrict: j['subDistrict'] ?? '',
    district: j['district'] ?? '',
    province: j['province'] ?? '',
    postalCode: j['postalCode'] ?? '',
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    isDefault: j['isDefault'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'recipientName': recipientName,
    'phone': phone,
    'addressLine': addressLine,
    'subDistrict': subDistrict,
    'district': district,
    'province': province,
    'postalCode': postalCode,
    'lat': lat,
    'lng': lng,
    'isDefault': isDefault,
  };
}
