import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/app_provider.dart';
import 'services/supabase_service.dart';
import 'utils/js_bridge.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initSupabase();

  // Register a global JS function so the PDF popup can trigger Flutter navigation.
  registerNavigateCallback((String path) {
    PanhaApp.router.go(path);
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const PanhaApp(),
    ),
  );
}
