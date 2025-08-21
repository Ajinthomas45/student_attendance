import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if(kIsWeb){
    await Firebase.initializeApp(options: FirebaseOptions(apiKey: "AIzaSyD4Bfjyvgg3fLAGsdXx7NIuTQCTDBa5vGE",
        authDomain: "student-attendance-b6f00.firebaseapp.com",
        projectId: "student-attendance-b6f00",
        storageBucket: "student-attendance-b6f00.firebasestorage.app",
        messagingSenderId: "1026857684696",
        appId: "1:1026857684696:web:43f11befc896dca05c11ad"));
  }else{
    await Firebase.initializeApp();
  }

  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DashboardScreen(),
    );
  }
}
