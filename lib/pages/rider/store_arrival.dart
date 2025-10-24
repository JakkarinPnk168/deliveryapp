import 'package:deliveryapp/pages/rider/delivery_customer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/order_model.dart';
import '../../controllers/store_arrival_controller.dart';
import '../../services/auth_service.dart';
import 'dart:io';

class StoreArrivalPage extends StatefulWidget {
  final Order order;

  const StoreArrivalPage({super.key, required this.order});

  @override
  State<StoreArrivalPage> createState() => _StoreArrivalPageState();
}

class _StoreArrivalPageState extends State<StoreArrivalPage> {
  late StoreArrivalController _controller;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = StoreArrivalController(
      order: widget.order,
      authService: AuthService(),
    );
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  // ถ่ายรูป
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        _controller.setPickupImage(photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ ยืนยันรับสินค้า - บันทึกภาพลงฐานข้อมูล และไปหน้าจัดส่ง
  Future<void> _confirmPickup() async {
    bool success = true;

    // ถ้ามีรูป ให้ confirmPickup() อัปโหลดและอัปเดตสถานะ
    if (_controller.pickupImagePath != null) {
      success = await _controller.confirmPickup();
    } else {
      // ถ้าไม่มีรูป ให้เรียก updateOrderStatus เป็น 3 (กำลังส่ง) เลย
      success = await _controller.updateStatusWithoutImage();
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รับสินค้าเรียบร้อยแล้ว กำลังนำไปส่งลูกค้า'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      // รอ 1 วินาที แล้วไปหน้าจัดส่งลูกค้า
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryToCustomerPage(
                order: widget.order.copyWith(status: 3),
              ),
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'เกิดข้อผิดพลาด'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Future<void> _confirmPickup() async {
  //   if (_controller.pickupImagePath == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('กรุณาถ่ายรูปสินค้าก่อน'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }

  //   // เรียก confirmPickup() เพื่ออัปโหลดรูปและอัปเดตสถานะเป็น 3 (กำลังจัดส่ง)
  //   final success = await _controller.confirmPickup();

  //   if (!mounted) return;

  //   if (success) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('รับสินค้าเรียบร้อยแล้ว กำลังนำไปส่งลูกค้า'),
  //         backgroundColor: Colors.green,
  //         duration: Duration(seconds: 1),
  //       ),
  //     );

  //     // รอ 1 วินาที แล้วไปหน้าจัดส่งลูกค้า (สถานะ 3)
  //     Future.delayed(const Duration(seconds: 1), () {
  //       if (mounted) {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => DeliveryToCustomerPage(
  //               order: widget.order.copyWith(status: 3), // อัปเดตสถานะ
  //             ),
  //           ),
  //         );
  //       }
  //     });
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(_controller.errorMessage ?? 'เกิดข้อผิดพลาด'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'สถานะ-ร้าน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // รูปภาพด้านบน
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/waiting_for_food.png',
                          height: 180,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '😋',
                                    style: TextStyle(
                                      fontSize: 40,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // การ์ดข้อมูลสินค้า
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'รับสินค้าที่ร้านแล้วก่อนดำเนินการ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ปุ่มถ่ายรูป
                        InkWell(
                          onTap: _controller.isLoading ? null : _takePhoto,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _controller.pickupImagePath != null
                                        ? Icons.check_circle
                                        : Icons.camera_alt,
                                    color: _controller.pickupImagePath != null
                                        ? Colors.green
                                        : Colors.grey[700],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _controller.pickupImagePath != null
                                            ? 'ถ่ายรูปแล้ว ✓'
                                            : 'ถ่ายรูปสินค้า',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              _controller.pickupImagePath !=
                                                  null
                                              ? Colors.green
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _controller.pickupImagePath != null
                                            ? 'แตะเพื่อถ่ายใหม่'
                                            : 'กดเพื่อถ่ายรูปหลักฐานสินค้า',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ✅ แสดงรูปที่ถ่าย
                        if (_controller.pickupImagePath != null) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_controller.pickupImagePath!),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ ปุ่มด้านล่าง "ร้านเตรียมเสร็จแล้ว"
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _controller.isLoading ? null : _confirmPickup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _controller.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'ร้านเตรียมเสร็จแล้ว',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
