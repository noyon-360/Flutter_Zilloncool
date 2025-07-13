import 'package:flutter/material.dart';
import 'package:flutx_core/core/routes/config/navigation_config.dart';
import 'package:word_game/routes/generate_routes.dart';

import 'package:url_strategy/url_strategy.dart';

void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

      initialRoute: AppRoutes.lavel,
    );
  }
}
