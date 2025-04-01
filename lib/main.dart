import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:qr_att/auth/loginscreen.dart';

import 'package:qr_att/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyDwXRhlMDjEpWRoedJxIDRH5S2ekA-z-u0",
        authDomain: "qratt-5f89a.firebaseapp.com",
        projectId: "qratt-5f89a",
        storageBucket: "qratt-5f89a.appspot.com",
        messagingSenderId: "350777898247",
        appId: "1:350777898247:web:9ac84ae09575587a47c1a2",
        measurementId: "G-ZSZLELFKNF"),
  );

  // Only check permissions on non-web platforms
  if (!kIsWeb) {
    await Permission.locationWhenInUse.isDenied.then((valueOfPermission) {
      if (valueOfPermission == true) {
        Permission.locationWhenInUse.request();
      }
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const KeyboardVisibilityProvider(
        child: AuthCheck(),
      ),
      localizationsDelegates: [
        MonthYearPickerLocalizations.delegate,
      ],
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool userAvailable = false;
  late SharedPreferences sharedPreferences;
  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    sharedPreferences = await SharedPreferences.getInstance();

    try {
      if (sharedPreferences.getString('studentId') != null) {
        setState(() {
          User.studentID = sharedPreferences.getString('studentId')!;
          userAvailable = true;
        });
      }
    } catch (e) {
      setState(() {
        userAvailable = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
    // return SignUpScreen();
  }
}
