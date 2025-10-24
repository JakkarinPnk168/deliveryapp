import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../services/api_service.dart';
import '../models/address_model.dart';

class AddressEditController extends GetxController {
  final ApiService api;
  final Future<String?> Function() tokenProvider;
  final String addressId;

  AddressEditController({
    required this.api,
    required this.tokenProvider,
    required this.addressId,
  });

  var loading = false.obs;
  var saving = false.obs;
  var deleting = false.obs;
  var errorMessage = ''.obs;

  Rxn<LatLng> selectedLocation = Rxn<LatLng>();

  var label = ''.obs;
  var recipientName = ''.obs;
  var phone = ''.obs;
  var addressDetail = ''.obs;
  var subDistrict = ''.obs;
  var district = ''.obs;
  var province = ''.obs;
  var postalCode = ''.obs;
  var isDefault = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAddress();
  }

  // ✅ โหลดข้อมูลที่อยู่จาก backend
  Future<void> loadAddress() async {
    loading.value = true;
    errorMessage.value = '';
    try {
      final token = await tokenProvider();
      if (token == null || token.isEmpty) throw Exception("Missing token");

      final address = await api.getAddressById(token, addressId);

      label.value = address.label;
      recipientName.value = address.recipientName ?? '';
      phone.value = address.phone ?? '';
      addressDetail.value = address.addressLine;
      subDistrict.value = address.subDistrict ?? '';
      district.value = address.district ?? '';
      province.value = address.province ?? '';
      postalCode.value = address.postalCode ?? '';
      isDefault.value = address.isDefault;
      selectedLocation.value = LatLng(
        address.lat.toDouble(),
        address.lng.toDouble(),
      );
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  // ✅ เมื่อเลือกจุดใหม่บนแผนที่
  void setSelected(LatLng pos) {
    selectedLocation.value = pos;
    reverseGeocode(pos);
  }

  // ✅ แปลงพิกัดเป็นที่อยู่ (ภาษาอังกฤษเรียงถูก)
  Future<void> reverseGeocode(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String street = (place.street ?? '').trim();
        final subLocality = (place.subLocality ?? '').trim();
        final locality = (place.locality ?? '').trim();
        final admin = (place.administrativeArea ?? '').trim();
        final postal = (place.postalCode ?? '').trim();

        addressDetail.value = [
          street,
          subLocality,
          locality,
        ].where((e) => e.isNotEmpty).join(', ');
        subDistrict.value = subLocality;
        district.value = locality;
        province.value = admin;
        postalCode.value = postal;
      }
    } catch (e) {
      errorMessage.value = 'Cannot reverse geocode: $e';
    }
  }

  // ✅ บันทึกข้อมูลที่อยู่
  Future<AddressModel?> saveChanges() async {
    if (saving.value) return null;
    saving.value = true;
    errorMessage.value = '';

    try {
      final token = await tokenProvider();
      if (token == null || token.isEmpty) throw Exception("Missing token");

      final pos = selectedLocation.value;

      final updated = await api.updateAddress(
        token,
        addressId,
        label: label.value,
        recipientName: recipientName.value,
        phone: phone.value,
        address_detail: addressDetail.value,
        subDistrict: subDistrict.value,
        district: district.value,
        province: province.value,
        postalCode: postalCode.value,
        gps_latitude: pos?.latitude,
        gps_longitude: pos?.longitude,
        isDefault: isDefault.value,
      );

      return updated;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      saving.value = false;
    }
  }

  // ✅ ลบที่อยู่
  Future<bool> deleteAddress() async {
    if (deleting.value) return false;
    deleting.value = true;
    try {
      final token = await tokenProvider();
      if (token == null || token.isEmpty) throw Exception("Missing token");
      await api.deleteAddress(token, addressId);
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      deleting.value = false;
    }
  }
}
