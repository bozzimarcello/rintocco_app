import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importa questo pacchetto
import 'package:rintocco_app/widgets/my_home_page.dart';

void main() {
  // Assicura che i binding di Flutter siano inizializzati
  WidgetsFlutterBinding.ensureInitialized();
  // Imposta gli orientamenti preferiti
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rintocco App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 234, 255, 0)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      home: const MyHomePage(title: 'Rintocco App'),
    );
  }
}
