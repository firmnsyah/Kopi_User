import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/mock_repository.dart';
import 'data/repository.dart';
import 'data/supabase_repository.dart';
import 'screens/login_screen.dart';
import 'screens/overview_screen.dart';
import 'state/session.dart';
import 'state/theme_controller.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

// ── Konfigurasi ────────────────────────────────────────────────────────────
const bool kUseMock = false;

// Nilai diinjeksi saat build via --dart-define-from-file=.env.json
const String kSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String kSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
// ──────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kUseMock) {
    assert(
      kSupabaseUrl.isNotEmpty && kSupabaseAnonKey.isNotEmpty,
      'Jalankan dengan: flutter run --dart-define-from-file=.env.json\n'
      'Salin .env.json.example → .env.json lalu isi kredensial Supabase.',
    );
    await Supabase.initialize(
      url: kSupabaseUrl,
      anonKey: kSupabaseAnonKey,
    );
  }

  final session = AppSession(supabaseMode: !kUseMock);
  await session.load();

  final themeController = await ThemeController.load();

  final Repository repository =
      kUseMock ? MockRepository() : SupabaseRepository();

  runApp(KopiUserApp(
    repository: repository,
    session: session,
    themeController: themeController,
  ));
}

class KopiUserApp extends StatelessWidget {
  final Repository repository;
  final AppSession session;
  final ThemeController themeController;

  const KopiUserApp({
    super.key,
    required this.repository,
    required this.session,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Repository>.value(value: repository),
        ChangeNotifierProvider<AppSession>.value(value: session),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
      ],
      child: Consumer<ThemeController>(
        builder: (_, theme, __) {
          // Sinkronkan palet adaptif sebelum MaterialApp & turunannya dibangun.
          AppColors.brightness = theme.brightness;
          return MaterialApp(
            title: 'Kopi User',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.mode,
            home: Consumer<AppSession>(
              builder: (_, s, __) {
                return s.isLoggedIn
                    ? const OverviewScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
