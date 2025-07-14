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
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(true);
  late SoundController _soundController;

  @override
  void initState() {
    super.initState();
    _soundController = SoundController();
    _initializeController();
  }

  Future<void> _initializeController() async {
    await _soundController.initialize();
    _isLoadingNotifier.value = false;
  }

  @override
  void dispose() {
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: _isLoadingNotifier,
          builder: (context, isLoading, child) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ValueListenableBuilder<bool>(
              valueListenable: _soundController.musicEnabledNotifier,
              builder: (context, isMusicEnabled, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _soundController.soundEnabledNotifier,
                  builder: (context, isSoundEnabled, child) {
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
                              value: isMusicEnabled,
                              onChanged: (newValue) async {
                                if (newValue && isSoundEnabled) {
                                  await _soundController.toggleSound();
                                }
                                await _soundController.toggleMusic();
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
                              opacity: isMusicEnabled ? 0.5 : 1.0,
                              child: CustomToggleButton(
                                value: isSoundEnabled,
                                onChanged: isMusicEnabled
                                    ? null
                                    : (newValue) async {
                                        await _soundController.toggleSound();
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
                              await _soundController.playButtonSound();
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
