class UserModel {
  final String userId;
  final String name;
  final String phone;
  final String role;
  final num wallet;
  final String? profileImage;
  final String? vehiclePlate;
  final String? vehicleImage;

  UserModel({
    required this.userId,
    required this.name,
    required this.phone,
    required this.role,
    required this.wallet,
    this.profileImage,
    this.vehiclePlate,
    this.vehicleImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      wallet: json['wallet'] ?? 0,
      profileImage: json['profileImage'],
      vehiclePlate: json['vehiclePlate'],
      vehicleImage: json['vehicleImage'],
    );
  }
}
