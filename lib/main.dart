import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/app_provider.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase for cloud sync.
  await initSupabase();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const PanhaApp(),
    ),
  );
}
