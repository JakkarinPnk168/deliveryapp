class AddressModel {
  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String subDistrict;
  final String district;
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
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? json['address_id'] ?? '',
      label: json['label'] ?? '',
      recipientName: json['recipientName'] ?? '',
      phone: json['phone'] ?? '',
      addressLine: json['address_detail'] ?? '',
      subDistrict: json['subDistrict'] ?? '',
      district: json['district'] ?? '',
      province: json['province'] ?? '',
      postalCode: json['postalCode'] ?? '',
      lat: (json['gps_latitude'] ?? 0).toDouble(),
      lng: (json['gps_longitude'] ?? 0).toDouble(),
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    "label": label,
    "recipientName": recipientName,
    "phone": phone,
    "address_detail": addressLine,
    "subDistrict": subDistrict,
    "district": district,
    "province": province,
    "postalCode": postalCode,
    "gps_latitude": lat,
    "gps_longitude": lng,
    "isDefault": isDefault,
  };
}
