import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'data/storage_service.dart';
import 'features/home/presentation/dashboard_screen.dart';
import 'features/reader/presentation/reader_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock to Portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Storage
  await storageService.init();

  // Set system UI overlay style for premium feel
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Light icons for dark background
    systemNavigationBarColor: Colors.transparent, 
    systemNavigationBarIconBrightness: Brightness.light, 
  ));
  
  // Enable edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const ProviderScope(child: PremiumPdfApp()));
}

// Simple Router Setup
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/reader',
      builder: (context, state) {
        final path = state.extra as String;
        return ReaderScreen(filePath: path);
      },
    ),
  ],
);

class PremiumPdfApp extends ConsumerWidget {
  const PremiumPdfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Manga Premium PDF Reader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark, 
      routerConfig: _router,
    );
  }
}
