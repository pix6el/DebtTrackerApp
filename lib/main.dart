import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'utils/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  runApp(const MyrDebtTrackerApp());
}

class MyrDebtTrackerApp extends StatelessWidget {
  const MyrDebtTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'MYR Debt Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF14B8A6),
              brightness: Brightness.dark,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
