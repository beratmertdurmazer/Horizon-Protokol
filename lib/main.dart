import 'package:flutter/material.dart';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/screens/splash_screen.dart';
import 'package:horizon_protocol/widgets/terminal_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://mpvcbfxzwqdhquvacukk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wdmNiZnh6d3FkaHF1dmFjdWtrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NzI4ODMsImV4cCI6MjA5MDA0ODg4M30.b47DOBJK9oitkpPW2_Z5WLN2cortNPPeMOmME3w3F64',
  );

  runApp(const HorizonProtocolApp());
}

class HorizonProtocolApp extends StatelessWidget {
  const HorizonProtocolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horizon Protokolü',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      builder: (context, child) {
        return TerminalOverlay(child: child!);
      },
    );
  }
}
