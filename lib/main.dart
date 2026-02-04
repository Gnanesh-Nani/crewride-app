import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'core/network/dio_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Ensure Dio and cookie jar are initialized before the app runs.
  await DioClient.init();

  runApp(const CrewRideApp());
}
