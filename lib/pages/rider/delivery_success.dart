import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';

class DeliverySuccessPage extends StatefulWidget {
  final Order order;
  const DeliverySuccessPage({super.key, required this.order});

  @override
  State<DeliverySuccessPage> createState() => _DeliverySuccessPageState();
}

class _DeliverySuccessPageState extends State<DeliverySuccessPage> {
  final _authService = AuthService();
  final _picker = ImagePicker();

  File? _deliveryImage;
  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _deliveryImage = File(pickedFile.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถเปิดกล้องได้: $e';
      });
    }
  }

  Future<void> _confirmDelivery() async {
    if (_deliveryImage == null) {
      setState(() {
        _errorMessage = 'กรุณาถ่ายรูปหลักฐานการส่งสินค้า';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.token;
      if (token == null) throw Exception('ไม่พบ Token');

      final orderService = OrderService(token);

      // อัปโหลดรูปพร้อมอัปเดตสถานะ 4 ส่งสำเร็จ
      final success = await orderService.updateOrderDelivery(
        orderId: widget.order.orderId,
        deliveryImagePath: _deliveryImage!.path,
      );

      if (!mounted) return;

      if (success) {
        _showSuccessDialog();
      } else {
        throw Exception('ไม่สามารถอัปเดตสถานะได้');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
        _isUploading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ส่งสินค้าสำเร็จ!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'คุณได้ส่งสินค้าเรียบร้อยแล้ว',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'กลับหน้าหลัก',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('กำลังส่ง'),
        backgroundColor: const Color(0xFF00C853),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ข้อมูลลูกค้า / สินค้า ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'ข้อมูลลูกค้า',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (widget.order.customerName != null &&
                            widget.order.customerName!.isNotEmpty)
                          Text('ชื่อลูกค้า: ${widget.order.customerName!}'),
                        const SizedBox(height: 8),
                        Text('ที่อยู่จัดส่ง: ${widget.order.addressDetail}'),
                        const SizedBox(height: 8),
                        Text('สินค้า: ${widget.order.productName}'),
                        if (widget.order.imageUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Image.network(
                              widget.order.imageUrl,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- ถ่ายรูปหลักฐานการส่ง ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: _isUploading ? null : _takePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _deliveryImage != null
                                    ? Colors.green
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _deliveryImage != null
                                      ? Icons.check_circle
                                      : Icons.camera_alt,
                                  color: _deliveryImage != null
                                      ? Colors.green
                                      : Colors.grey[700],
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _deliveryImage != null
                                        ? 'ถ่ายรูปแล้ว ✓'
                                        : 'ถ่ายรูปหลักฐาน',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_deliveryImage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Image.file(
                              _deliveryImage!,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // --- ปุ่มยืนยัน ---
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _confirmDelivery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('ยืนยันส่งสินค้าสำเร็จ'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
