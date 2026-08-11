import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/aqi_record.dart';
import 'providers/auth_provider.dart';
import 'providers/aqi_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for all supported locales
  await initializeDateFormatting('en');
  await initializeDateFormatting('te');
  await initializeDateFormatting('hi');
  await initializeDateFormatting('ta');

  // Initialize API service
  await ApiService.init();

  // Initialize in-app push notifications
  await NotificationService.init();

  // Initialize WorkManager background tasks (Android/iOS only)
  if (!kIsWeb) {
    await initBackgroundService();
  }

  // Initialize Hive
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(AqiRecordAdapter());
  }
  await Hive.openBox<AqiRecord>('aqi_records');

  runApp(const AeroSenseApp());
}

class AeroSenseApp extends StatelessWidget {
  const AeroSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AqiProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'AeroSense',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
