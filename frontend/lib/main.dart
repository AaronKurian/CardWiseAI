import 'package:cardwise_ai/providers/app_providers.dart';
import 'package:cardwise_ai/screens/app_shell.dart';
import 'package:cardwise_ai/screens/auth_screen.dart';
import 'package:cardwise_ai/services/api_client.dart';
import 'package:cardwise_ai/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const CardWiseApp());
}

class CardWiseApp extends StatelessWidget {
  const CardWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildProviders(ApiClient()),
      child: MaterialApp(
        title: 'CardWise',
        debugShowCheckedModeBanner: false,
        theme: _darkTheme(),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.ready) {
              return const Scaffold(body: LoadingOverlay());
            }
            return auth.isAuthenticated ? const AppShell() : const AuthScreen();
          },
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    const background = Color(0xFF070A0F);
    const surface = Color(0xFF111827);
    const accent = Color(0xFF22C55E);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: Color(0xFF38BDF8),
        surface: surface,
        error: Color(0xFFF87171),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF263244)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF263244)),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
