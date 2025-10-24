import 'package:deliveryapp/firebase_options.dart';
import 'package:deliveryapp/pages/address_add.dart';
import 'package:deliveryapp/pages/address_edit.dart';
import 'package:deliveryapp/pages/edit_profile.dart';
import 'package:deliveryapp/pages/home_rider.dart';
import 'package:deliveryapp/pages/home_user.dart';
import 'package:deliveryapp/pages/login.dart';
import 'package:deliveryapp/pages/profile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DeliveryApp',
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      initialRoute: "/login",

      getPages: [
        GetPage(name: "/login", page: () => const LoginPage()),
        GetPage(name: "/homeUser", page: () => const UserHomePage()),
        GetPage(name: "/profile", page: () => const ProfilePage()),
        GetPage(name: "/editProfile", page: () => const EditProfilePage()),
        GetPage(name: "/homeRider", page: () => const RiderHomePage()),
        GetPage(name: "/addressAdd", page: () => const AddressAddPage()),
        GetPage(name: "/parcel", page: () => const AddressAddPage()),
        GetPage(
          name: "/addressEdit",
          page: () {
            final id = Get.parameters['id'];
            return AddressEditPage(addressId: id ?? '');
          },
        ),
      ],
    );
  }
}
