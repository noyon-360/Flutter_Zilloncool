import 'package:flutter/material.dart';
import 'package:flutx_core/core/routes/services/go_next_navigation.dart';
import 'package:word_game/routes/generate_routes.dart';
import '../widgets/custom_toggle_button.dart';
import '../controllers/sound_controller.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    await SoundController().initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Drawer(
        child: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    return Drawer(
      child: SafeArea(
        child: AnimatedBuilder(
          animation: SoundController(),
          builder: (context, child) {
            final soundController = SoundController();

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 20),

                // Music Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    title: const Text(
                      'Music',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: CustomToggleButton(
                      value: soundController.isMusicEnabled,
                      onChanged: (newValue) async {
                        if (newValue) {
                          // When turning music ON, force sound OFF
                          if (soundController.isSoundEnabled) {
                            await soundController.toggleSound();
                          }
                        }
                        await soundController.toggleMusic();
                      },
                    ),
                  ),
                ),

                // Sound Effects Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    title: const Text(
                      'Sound',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Opacity(
                      opacity: soundController.isMusicEnabled ? 0.5 : 1.0,
                      child: CustomToggleButton(
                        value: soundController.isSoundEnabled,
                        onChanged: soundController.isMusicEnabled
                            ? null
                            : (newValue) async {
                                await soundController.toggleSound();
                              },
                      ),
                    ),
                  ),
                ),

                const Divider(),
                const SizedBox(height: 20),

                // Privacy Policy Button
                Center(
                  child: InkWell(
                    onTap: () async {
                      await SoundController().playButtonSound();
                      Go.sailTo(AppRoutes.privacy);
                    },
                    child: SizedBox(
                      height: 40,
                      width: 180,
                      child: Image.asset("assets/privacy_policy_button.png"),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
