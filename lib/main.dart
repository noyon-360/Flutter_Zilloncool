import 'package:flutter/material.dart';
import 'package:flutx_core/core/routes/config/navigation_config.dart';
import 'package:word_game/routes/generate_routes.dart';

import 'presentation/controllers/sound_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sound controller
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      navigatorKey: NavigationConfig.navigatorKey,
      navigatorObservers: NavigationConfig.navigatorObservers,
      onGenerateRoute: RouteGenerate.generateRoute,

      initialRoute: AppRoutes.splash,
    );
  }
}
