import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
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
      title: 'Konsept Bulmaca',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB45309),
          surface: const Color(0xFFF8F6F1),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F6F1),
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
    return const Scaffold(
      backgroundColor: Color(0xFFF8F6F1),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFB45309)),
            SizedBox(height: 16),
            Text(
              'Konsept Bulmacalar Hazırlanıyor...',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF57534E),
              ),
            ),
          ],
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
