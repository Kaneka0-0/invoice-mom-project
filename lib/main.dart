import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;
import 'app.dart';
import 'providers/app_provider.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initSupabase();

  // Register a global JS function so the PDF popup can trigger Flutter navigation.
  if (kIsWeb) {
    js.context['_panhaNavigate'] = (String path) {
      PanhaApp.router.go(path);
    };
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const PanhaApp(),
    ),
  );
}
