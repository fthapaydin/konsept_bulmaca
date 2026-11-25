import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'core/brand/brand_config.dart';
import 'core/theme/app_theme.dart';
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
          seedColor: AppPalette.brass,
          surface: AppPalette.paper,
        ),
        scaffoldBackgroundColor: AppPalette.paper,
      ),
      home: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          if (_appState.isLoading) {
            return const EkareSplashView();
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

class EkareSplashView extends StatelessWidget {
  const EkareSplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandConfig.newsprintPaper,
      body: Container(
        color: BrandConfig.newsprintPaper,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    color: BrandConfig.newsprintPaper,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: BrandConfig.newsprintInk,
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      BrandConfig.iconAssetPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  BrandConfig.appName,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: BrandConfig.newsprintInk,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 54,
                  height: 1.5,
                  color: BrandConfig.newsprintInk.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 8),
                Text(
                  BrandConfig.tagline.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: AppPalette.inkSoft,
                  ),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 136,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: AppPalette.hairline,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        BrandConfig.newsprintInk,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bulmacalar hazırlanıyor...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.inkMuted,
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  '${BrandConfig.developerName} • ${BrandConfig.versionLabel}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppPalette.inkMuted,
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
