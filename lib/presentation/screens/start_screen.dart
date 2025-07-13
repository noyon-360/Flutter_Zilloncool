import 'package:flutter/material.dart';
import 'package:flutx_core/core/routes/services/go_next_navigation.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:word_game/routes/generate_routes.dart';

import '../controllers/sound_controller.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/start_play_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Centered widget
              Center(
                child: Container(
                  height: 372.94,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: AssetImage('assets/start_word_bg.png'),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Image.asset('assets/logo.png', width: 264),
                  ), // Example centered widget
                ),
              ),

              Center(
                child: Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        Go.sailTo(AppRoutes.lavel);
                        await SoundController().playButtonSound();
                      },
                      child: Image.asset(
                        'assets/play_button.png',
                        width: 239,
                        height: 70,
                      ),
                    ),
                    Gap.h32,
                    Image.asset(
                      'assets/more_game_button.png',
                      width: 239,
                      height: 70,
                    ),
                    Gap.bottomBarGap,
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
      ),
    );
  }
}
