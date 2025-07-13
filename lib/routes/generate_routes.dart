import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:word_game/presentation/screens/game_screen.dart';
import 'package:word_game/presentation/screens/level_selection_screen.dart';

class AppRoutes {
  static const String start = '/';
  static const String lavel = '/lavel-screen';
  static const String game = '/game-screen';
}

class RouteGenerate {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Handle deep linking for web
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path;

    switch (path) {
      /// [Level Select Screen]
      case AppRoutes.lavel:
        return SlideUpTransition(page: LevelSelectionScreen());

      case AppRoutes.game:
        if (settings.arguments is Map) {
          final arg = settings.arguments as Map;
          if (arg['level'] != null) {
            return SlideLeftTransition(page: GameScreen(level: arg['level']));
          }
        }
        return _errorRoute();
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
