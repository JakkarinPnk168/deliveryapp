import 'package:deliveryapp/firebase_options.dart';
import 'package:deliveryapp/pages/edit_profile.dart';
<<<<<<< HEAD
import 'package:deliveryapp/pages/rider/home_rider.dart';
import 'package:deliveryapp/pages/home_user.dart';
import 'package:deliveryapp/pages/login.dart';
import 'package:deliveryapp/pages/profile.dart';
import 'package:deliveryapp/pages/rider/rider_map_page.dart';
=======
import 'package:deliveryapp/pages/home_rider.dart';
import 'package:deliveryapp/pages/home_user.dart';
import 'package:deliveryapp/pages/login.dart';
import 'package:deliveryapp/pages/profile.dart';
>>>>>>> 6916f3ce840ffa46de1a4cf3f0f21127ced845df
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DeliveryApp',
      theme: ThemeData(primarySwatch: Colors.deepOrange),
<<<<<<< HEAD
      // home: const RiderPickupPage(),
=======
>>>>>>> 6916f3ce840ffa46de1a4cf3f0f21127ced845df
      initialRoute: "/login",
      routes: {
        "/login": (context) => const LoginPage(),
        "/homeUser": (context) => const UserHomePage(),
        "/profile": (context) => const ProfilePage(),
        '/editProfile': (context) => const EditProfilePage(),
        "/homeRider": (context) => const RiderHomePage(),
      },
    );
  }
}
