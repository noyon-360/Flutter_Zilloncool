import 'package:flutter/material.dart';
import 'package:flutx_core/core/routes/services/go_next_navigation.dart';
import 'package:word_game/routes/generate_routes.dart';

// import '../controllers/sound_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Go.freshStartTo(AppRoutes.start);
      // nextMove();
    });
  }

  // void nextMove() async {
  //   await SoundController().playButtonSound();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/start_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Centered widget
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 264,
                  ), // Example centered widget
                ],
              ),
            ),

            // Bottom widget
            // Positioned(
            //   bottom: 40, // Adjust this value as needed
            //   left: 0,
            //   right: 0,
            //   child: Column(
            //     children: [
            //       ElevatedButton(
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.blue,
            //           padding: const EdgeInsets.symmetric(
            //             horizontal: 40,
            //             vertical: 15,
            //           ),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(30),
            //           ),
            //         ),
            //         onPressed: () {
            //           // Navigate to next screen
            //         },
            //         child: const Text(
            //           'START GAME',
            //           style: TextStyle(
            //             fontSize: 18,
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //           ),
            //         ),
            //       ),
            //       const SizedBox(height: 20),
            //       const Text(
            //         'v1.0.0',
            //         style: TextStyle(color: Colors.white70, fontSize: 14),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
