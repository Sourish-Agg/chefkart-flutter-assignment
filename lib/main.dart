import 'package:flutter/material.dart';
import 'screens/select_dishes_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChefKart',
        theme: ThemeData(
          fontFamily: 'Roboto',
          textTheme: const TextTheme(
            headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
            headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
            bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
            bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
            bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),

        home: const SelectDishesScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
