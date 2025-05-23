import 'package:flutter/material.dart';
import 'package:rintocco_app/widgets/my_home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 32, 122, 232)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Rintocco App Home Page'),
    );
  }
}
