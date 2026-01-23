import 'package:suara_surabaya_admin/app_initializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Pastikan binding siap SEBELUM memanggil async
  WidgetsFlutterBinding.ensureInitialized();
  
  // Muat dotenv di sini, di paling awal
  await dotenv.load(fileName: ".env");

  // Jalankan aplikasi dengan initializer
  runApp(const AppInitializer());
}