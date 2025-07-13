import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:word_game/presentation/screens/game_screen.dart';
import 'package:word_game/presentation/screens/level_selection_screen.dart';
import 'package:word_game/presentation/screens/privacy_policy_screen.dart';
import 'package:word_game/presentation/screens/splash_screen.dart';
import 'package:word_game/presentation/screens/start_screen.dart';

abstract class AppRoutes {
  static const String splash = '/';
  static const String start = '/start';
  static const String lavel = '/lavel-screen';
  static const String game = '/game-screen';
  static const String privacy = '/privacy-screen';
}

class RouteGenerate {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Handle deep linking for web
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path;

    switch (path) {
      case AppRoutes.splash:
        return FadeRoute(duration: Duration(seconds: 3), page: SplashScreen());

      case AppRoutes.start:
        return SlideUpTransition(
          duration: Duration(seconds: 1),
          page: StartScreen(),
        );

      /// [Level Select Screen]
      case AppRoutes.lavel:
        return SlideLeftTransition(page: LevelSelectionScreen());

      case AppRoutes.game:
        if (settings.arguments is Map) {
          final arg = settings.arguments as Map;
          if (arg['level'] != null) {
            return SlideLeftTransition(page: GameScreen(level: arg['level']));
          }
        }
        return _errorRoute();

      /// [Privacy Policy]
      case AppRoutes.privacy:
        return SlideLeftTransition(page: PrivacyPolicyScreen());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(body: Center(child: Text('Route not found'))),
    );
  }
}
