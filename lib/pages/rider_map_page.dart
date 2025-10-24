import 'package:deliveryapp/controllers/register_rider_controller.dart';
import 'package:deliveryapp/controllers/rider_map_controller.dart';
import 'package:deliveryapp/pages/store_arrival.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';

class RiderMapPage extends StatefulWidget {
  final Order order;

  const RiderMapPage({super.key, required this.order});

  @override
  State<RiderMapPage> createState() => _RiderMapPageState();
}

class _RiderMapPageState extends State<RiderMapPage> {
  final MapController _mapController = MapController();
  late RiderMapController _controller;
  bool _showRoute = false;

  @override
  void initState() {
    super.initState();
    _controller = RiderMapController(
      order: widget.order,
      authService: AuthService(),
    );
    _controller.addListener(_onControllerUpdate);
    _controller.initialize();
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

  // ✅ ปุ่ม "ไปที่" - แสดงเส้นทางบนแผนที่
  Future<void> _showRouteOnMap() async {
    setState(() {
      _showRoute = true;
    });

    // ถ้ายังไม่มีเส้นทาง ให้ดึงมา
    if (_controller.routePoints.isEmpty) {
      await _controller.fetchRoute();
    }

    // ปรับมุมมองแผนที่ให้เห็นทั้งเส้นทาง
    if (_controller.currentPosition != null && mounted) {
      final bounds = LatLngBounds(
        _controller.currentPosition!,
        LatLng(widget.order.lat, widget.order.lng),
      );

      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(100)),
      );
    }
  }

  // ✅ เปิด Google Maps Navigation
  Future<void> _openNavigation() async {
    final lat = widget.order.lat;
    final lng = widget.order.lng;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'ไม่สามารถเปิด Google Maps ได้';
      }
    } catch (e) {
      if (mounted) {
        await _showRouteOnMap();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('แสดงเส้นทางบนแผนที่แทน'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  // ✅ กดปุ่ม "ถึงแล้ว" - ไปหน้าสถานะร้าน (Store Arrival)
  void _onArrived() {
    // ตรวจสอบระยะห่างก่อน (ไม่เกิน 20 เมตร)
    if (_controller.currentPosition != null) {
      final distance = _controller.calculateDistance(
        _controller.currentPosition!.latitude,
        _controller.currentPosition!.longitude,
        widget.order.lat,
        widget.order.lng,
      );

      // ถ้าห่างเกิน 20 เมตร แสดงเตือน
      if (distance > 1000) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'คุณอยู่ห่างจากร้าน ${distance.toStringAsFixed(0)} เมตร\nกรุณาเข้าใกล้ร้านให้ไม่เกิน 20 เมตร',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // ถ้าอยู่ใกล้พอ ไปหน้าสถานะร้าน
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreArrivalPage(order: widget.order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller.loadingLocation
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังค้นหาตำแหน่ง...'),
                ],
              ),
            )
          : _controller.errorMessage != null &&
                _controller.currentPosition == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _controller.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _controller.initialize,
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // ✅ แผนที่
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _controller.currentPosition ??
                        LatLng(widget.order.lat, widget.order.lng),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.deliveryapp',
                    ),

                    // ✅ เส้นทาง
                    if (_showRoute && _controller.routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _controller.routePoints,
                            strokeWidth: 4.0,
                            color: Colors.blue,
                          ),
                        ],
                      ),

                    // ✅ Markers
                    MarkerLayer(
                      markers: [
                        // ตำแหน่งปัจจุบัน (Rider)
                        if (_controller.currentPosition != null)
                          Marker(
                            point: _controller.currentPosition!,
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.delivery_dining,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),

                        // จุดหมาย (ร้าน)
                        if (_showRoute)
                          Marker(
                            point: LatLng(widget.order.lat, widget.order.lng),
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // ✅ ปุ่ม Back
                Positioned(
                  top: 50,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                // ✅ ปุ่มนำทาง
                if (_showRoute)
                  Positioned(
                    top: 50,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.navigation, color: Colors.white),
                        onPressed: _openNavigation,
                        tooltip: 'เปิด Google Maps',
                      ),
                    ),
                  ),

                // ✅ Bottom Sheet
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // แถบสถานะ
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _controller
                                      .getStatusColor(_controller.currentStatus)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.local_shipping,
                                  color: _controller.getStatusColor(
                                    _controller.currentStatus,
                                  ),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _controller.getStatusText(
                                        _controller.currentStatus,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _showRoute
                                          ? 'ระยะทาง ${_controller.getDistanceText()}'
                                          : 'กดปุ่ม "ไปที่" เพื่อแสดงเส้นทาง',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_showRoute)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.navigation,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const Divider(
                          color: Colors.grey,
                          height: 1,
                          thickness: 0.5,
                        ),

                        // ข้อมูลร้าน
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.order.productName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.order.addressDetail,
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (widget.order.imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    widget.order.imageUrl,
                                    height: 80,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // ปุ่มด้านล่าง
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Row(
                            children: [
                              // ปุ่ม "ไปที่"
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showRoute
                                      ? null
                                      : _showRouteOnMap,
                                  icon: Icon(
                                    _showRoute ? Icons.check : Icons.directions,
                                  ),
                                  label: Text(
                                    _showRoute ? 'กำลังนำทาง' : 'ไปที่',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _showRoute
                                        ? Colors.grey[700]
                                        : Colors.white,
                                    foregroundColor: _showRoute
                                        ? Colors.white
                                        : Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // ปุ่ม "ถึงแล้ว"
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _onArrived,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00C853),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'ถึงแล้ว',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading overlay
                if (_controller.loadingRoute)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'กำลังคำนวณเส้นทาง...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
