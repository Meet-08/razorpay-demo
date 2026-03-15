import 'package:client/pages/payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D4ED8),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF1D4ED8),
          secondary: const Color(0xFF0EA5E9),
          surface: const Color(0xFFFFFFFF),
        );

    return MaterialApp(
      title: 'Razorpay Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFEAF2FF),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
        ),
      ),
      home: const Payment(),
    );
  }
}
