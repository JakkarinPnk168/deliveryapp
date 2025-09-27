import 'package:deliveryapp/firebase_options.dart';
import 'package:deliveryapp/pages/home_rider.dart';
import 'package:deliveryapp/pages/home_user.dart';
import 'package:deliveryapp/pages/login.dart';
import 'package:deliveryapp/pages/profile.dart';
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
      initialRoute: "/login", // 👈 กำหนด route แรก
      routes: {
        "/login": (context) => const LoginPage(),
        "/homeUser": (context) => const UserHomePage(),
        "/profile": (context) => const ProfilePage(),

        "/homeRider": (context) => const RiderHomePage(),
      },
    );
  }
}
