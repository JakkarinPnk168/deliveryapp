import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../models/address_model.dart';

class AddressAddController extends GetxController {
  final ApiService api;
  final Future<String?> Function() tokenProvider;

  AddressAddController({required this.api, required this.tokenProvider});

  var loading = false.obs;
  var locating = false.obs;
  var saving = false.obs;
  var errorMessage = ''.obs;

  Rxn<LatLng> selectedLocation = Rxn<LatLng>();

  // ✅ ใช้ TextEditingController ถาวร
  final addressDetailController = TextEditingController();
  final subDistrictController = TextEditingController();
  final districtController = TextEditingController();
  final provinceController = TextEditingController();
  final postalCodeController = TextEditingController();

  // ถ้าอยากเก็บเป็น observable ด้วย
  var label = ''.obs;
  var recipientName = ''.obs;
  var phone = ''.obs;
  var addressDetail = ''.obs;
  var subDistrict = ''.obs;
  var district = ''.obs;
  var province = ''.obs;
  var postalCode = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // sync controller ↔ observable
    addressDetailController.addListener(() {
      addressDetail.value = addressDetailController.text;
    });
    subDistrictController.addListener(() {
      subDistrict.value = subDistrictController.text;
    });
    districtController.addListener(() {
      district.value = districtController.text;
    });
    provinceController.addListener(() {
      province.value = provinceController.text;
    });
    postalCodeController.addListener(() {
      postalCode.value = postalCodeController.text;
    });
  }

  @override
  void onClose() {
    addressDetailController.dispose();
    subDistrictController.dispose();
    districtController.dispose();
    provinceController.dispose();
    postalCodeController.dispose();
    super.onClose();
  }

  void setSelected(LatLng position) {
    selectedLocation.value = position;
    reverseGeocode(position);
  }

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
        final country = (place.country ?? '').trim();

        if (street.contains('+') && street.length <= 15) street = '';

        final line1 = [
          if (street.isNotEmpty) street,
          if (subLocality.isNotEmpty) subLocality,
          if (locality.isNotEmpty) locality,
        ].join(', ');

        final line2 = [
          if (admin.isNotEmpty) admin,
          if (postal.isNotEmpty) postal,
          if (country.isNotEmpty) country,
        ].join(', ');

        // ✅ set ค่าเข้า controller
        addressDetailController.text = "$line1\n$line2";
        subDistrictController.text = subLocality;
        districtController.text = locality;
        provinceController.text = admin;
        postalCodeController.text = postal;
      } else {
        errorMessage.value = 'No placemark found for this location.';
      }
    } catch (e) {
      errorMessage.value = 'Cannot get address: $e';
    }
  }

  Future<void> useCurrentLocation() async {
    locating.value = true;
    errorMessage.value = '';

    try {
      final pos = await getCurrentLatLng();
      if (pos != null) {
        selectedLocation.value = pos;
        await reverseGeocode(pos);
      } else {
        errorMessage.value = 'Cannot fetch current location';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching location: ${e.toString()}';
    } finally {
      locating.value = false;
    }
  }

  Future<LatLng?> getCurrentLatLng() async {
    final status = await Permission.location.request();
    if (!status.isGranted) return null;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(pos.latitude, pos.longitude);
  }

  Future<AddressModel?> submit() async {
    if (saving.value) return null;
    saving.value = true;

    try {
      final token = await tokenProvider();
      if (token == null || token.isEmpty) throw Exception("Missing token");

      final loc = selectedLocation.value;

      final address = AddressModel(
        id: '',
        label: label.value.isEmpty ? 'ที่อยู่ใหม่' : label.value,
        recipientName: recipientName.value,
        phone: phone.value,
        addressLine: addressDetailController.text,
        subDistrict: subDistrictController.text,
        district: districtController.text,
        province: provinceController.text,
        postalCode: postalCodeController.text,
        lat: loc?.latitude ?? 0,
        lng: loc?.longitude ?? 0,
        isDefault: false,
      );

      final result = await api.createAddress(token, address);
      saving.value = false;
      return result;
    } catch (e) {
      errorMessage.value = e.toString();
      saving.value = false;
      return null;
    }
  }
}
