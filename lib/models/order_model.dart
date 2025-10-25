class Order {
  final String orderId;
  final String productName;
  final String senderId;
  final String receiverId;

  // Customer name (optional)
  final String? customerName;

  // Address
  final String addressLabel;
  final String addressDetail;
  final double lat;
  final double lng;

  final int status;
  final String imageUrl;
  final String proofImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.orderId,
    required this.productName,
    required this.senderId,
    required this.receiverId,
    this.customerName,
    required this.addressLabel,
    required this.addressDetail,
    required this.lat,
    required this.lng,
    required this.status,
    required this.imageUrl,
    required this.proofImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ Factory method สำหรับ Firebase / JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    final addressObj = json['address'] as Map<String, dynamic>? ?? {};
    final items = json['items'] as List<dynamic>? ?? [];

    String productName = '';
    String imageUrl = '';

    if (items.isNotEmpty) {
      final firstItem = items[0] as Map<String, dynamic>;
      productName = firstItem['productName'] ?? '';
      imageUrl = firstItem['imageUrl'] ?? '';
    }

    return Order(
      orderId: json['orderId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      customerName: json['customerName'] as String?,
      productName: productName,
      addressLabel: addressObj['label'] ?? '',
      addressDetail: addressObj['address'] ?? '',
      lat: (addressObj['lat'] is num)
          ? (addressObj['lat'] as num).toDouble()
          : 0.0,
      lng: (addressObj['lng'] is num)
          ? (addressObj['lng'] as num).toDouble()
          : 0.0,
      status: json['status'] ?? 0,
      imageUrl: imageUrl,
      proofImageUrl: json['proofImageUrl'] ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
    );
  }

  // รองรับ Firebase Timestamp หรือ ISO8601 string
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Map && value.containsKey('_seconds')) {
      final seconds = value['_seconds'] as int;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }

  // ✅ แปลงกลับเป็น JSON
  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'senderId': senderId,
    'receiverId': receiverId,
    'customerName': customerName,
    'items': [
      {'productName': productName, 'imageUrl': imageUrl},
    ],
    'address': {
      'label': addressLabel,
      'address': addressDetail,
      'lat': lat,
      'lng': lng,
    },
    'status': status,
    'proofImageUrl': proofImageUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  // ✅ copyWith สำหรับแก้ไขบาง field
  Order copyWith({
    String? orderId,
    String? productName,
    String? senderId,
    String? receiverId,
    String? customerName,
    String? addressLabel,
    String? addressDetail,
    double? lat,
    double? lng,
    int? status,
    String? imageUrl,
    String? proofImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      productName: productName ?? this.productName,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      customerName: customerName ?? this.customerName,
      addressLabel: addressLabel ?? this.addressLabel,
      addressDetail: addressDetail ?? this.addressDetail,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
