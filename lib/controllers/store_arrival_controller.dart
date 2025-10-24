import 'package:deliveryapp/services/orders_service.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
// import '../services/order_service.dart';

class StoreArrivalController extends ChangeNotifier {
  final Order order;
  final AuthService authService;
  OrdersService? _orderService;

  bool _isLoading = false;
  String? _errorMessage;
  String? _pickupImagePath;

  StoreArrivalController({required this.order, required this.authService}) {
    _initialize();
  }

  // เตรียม OrderService
  Future<void> _initialize() async {
    final token = await authService.token; // ดึงจาก secure storage
    if (token == null || token.isEmpty) {
      _errorMessage = 'กรุณาเข้าสู่ระบบก่อน';
      notifyListeners();
      return;
    }
    _orderService = OrdersService(token);
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get pickupImagePath => _pickupImagePath;

  // ตั้งค่ารูปภาพที่ถ่าย
  void setPickupImage(String path) {
    _pickupImagePath = path;
    _errorMessage = null;
    notifyListeners();
  }

  // ยืนยันรับสินค้าจากร้าน
  Future<bool> confirmPickup() async {
    if (_pickupImagePath == null) {
      _errorMessage = 'กรุณาถ่ายรูปสินค้าก่อน';
      notifyListeners();
      return false;
    }

    if (_orderService == null) {
      await _initialize();
      if (_orderService == null) return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final success = await _orderService!.updateOrderPickup(
      orderId: order.orderId,
      pickupImagePath: _pickupImagePath,
    );

    _isLoading = false;
    if (!success) _errorMessage = 'ไม่สามารถอัปเดตสถานะได้';
    notifyListeners();
    return success;
  }

  // อัปเดตสถานะเป็น 3 โดยไม่ต้องถ่ายรูป
  Future<bool> updateStatusWithoutImage() async {
    if (_orderService == null) {
      await _initialize();
      if (_orderService == null) {
        _errorMessage = 'ไม่สามารถเริ่มต้นระบบได้';
        notifyListeners();
        return false;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _orderService!.updateOrderStatus(
        orderId: order.orderId,
        newStatus: 3, // กำลังส่ง
      );

      _isLoading = false;
      if (success) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'ไม่สามารถอัปเดตสถานะได้';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
