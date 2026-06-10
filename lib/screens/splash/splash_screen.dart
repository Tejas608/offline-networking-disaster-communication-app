import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    checkProfile();
  }

  Future<void> checkProfile() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    await profileProvider.loadProfile();

    Timer(const Duration(seconds: 2), () {
      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  profileProvider.hasProfile
                      ? const HomeScreen()
                      : const RegistrationScreen(),
        ),
      );
    });
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
