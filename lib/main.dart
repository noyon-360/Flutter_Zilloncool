import 'package:flutter/material.dart';
import 'package:flutx_core/core/routes/config/navigation_config.dart';
import 'package:word_game/routes/generate_routes.dart';
import 'presentation/controllers/sound_controller.dart';
import 'presentation/widgets/performance_monitor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize optimized sound controller
  await SoundController().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SoundController().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        SoundController().resumeMusic();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        SoundController().pauseMusic();
        break;
      case AppLifecycleState.detached:
        SoundController().dispose();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Optimized Word Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      navigatorKey: NavigationConfig.navigatorKey,
      navigatorObservers: NavigationConfig.navigatorObservers,
      onGenerateRoute: RouteGenerate.generateRoute,
      initialRoute: AppRoutes.splash,
      builder: (context, child) {
        // Wrap with performance monitor (only in debug mode)
        return SoundPerformanceMonitor(
          showOverlay: false, // Set to true for debugging
          child: child ?? Container(),
        );
      },
    );
  }
}
