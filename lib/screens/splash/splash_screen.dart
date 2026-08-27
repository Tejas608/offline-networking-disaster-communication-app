import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../providers/profile_provider.dart';
import '../home/home_screen.dart';
import '../onboarding/registration_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _checkProfile();
  }

  Future<void> _checkProfile() async {
    final ProfileProvider profileProvider = context.read<ProfileProvider>();

    final ChatProvider chatProvider = context.read<ChatProvider>();

    await profileProvider.loadProfile();

    await chatProvider.initialize();

    await chatProvider.refreshLocalProfile();

    await chatProvider.loadConnectedUsers();

    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) =>
                profileProvider.hasProfile
                    ? const HomeScreen()
                    : const RegistrationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_tethering, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'OFFLINE DISASTER CONNECT',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Stay Connected Without Internet'),
          ],
        ),
      ),
    );
  }
}
