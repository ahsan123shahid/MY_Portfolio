import 'package:flutter/material.dart';
import 'package:myproject/Screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barani Quiz',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
