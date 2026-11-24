import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'core/brand/brand_config.dart';
import 'screens/home_screen.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const KonseptBulmacaApp());
}

class KonseptBulmacaApp extends StatefulWidget {
  const KonseptBulmacaApp({super.key, this.appState});

  final AppState? appState;

  @override
  State<KonseptBulmacaApp> createState() => _KonseptBulmacaAppState();
}

class _KonseptBulmacaAppState extends State<KonseptBulmacaApp> {
  late final AppState _appState;
  late final bool _ownsAppState;

  @override
  void initState() {
    super.initState();
    _ownsAppState = widget.appState == null;
    _appState = widget.appState ?? AppState();
    if (_appState.isLoading) {
      _appState.initialize();
    }
  }

  @override
  void dispose() {
    if (_ownsAppState) {
      _appState.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: BrandConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: BrandConfig.primaryAmber,
          surface: BrandConfig.warmPaper,
        ),
        scaffoldBackgroundColor: BrandConfig.warmPaper,
      ),
      home: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          if (_appState.isLoading) {
            return const _SplashLoadingView();
          }
          if (_appState.error != null) {
            return _ErrorRetryView(
              message: _appState.error!,
              onRetry: _appState.initialize,
            );
          }
          return HomeScreen(appState: _appState);
        },
      ),
    );
  }
}

class _SplashLoadingView extends StatelessWidget {
  const _SplashLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandConfig.splashDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF451A03), BrandConfig.splashDark, Color(0xFF1A0B05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/branding/karehane_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  BrandConfig.appName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  BrandConfig.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFDE68A).withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      backgroundColor: Color(0xFF572914),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bulmaca dünyası hazırlanıyor...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorRetryView extends StatelessWidget {
  const _ErrorRetryView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF44403C)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
