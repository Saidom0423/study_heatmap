import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  runApp(const StudyHeatmapApp());
}

class StudyHeatmapApp extends StatelessWidget {
  const StudyHeatmapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return MaterialApp(
      title: 'Study Heatmap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: session != null
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}