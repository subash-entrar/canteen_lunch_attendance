import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/attendance_provider.dart';
import 'providers/report_provider.dart';
import 'providers/students_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cap decoded image memory — full-res profile photos can OOM otherwise.
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 120;
  imageCache.maximumSizeBytes = 48 << 20; // 48 MB
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => StudentsProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: const CanteenLunchApp(),
    ),
  );
}
