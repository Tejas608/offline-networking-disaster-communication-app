import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/location_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/nearby_users_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/profile_provider.dart';

import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const OfflineNetworkApp());
}

class OfflineNetworkApp extends StatelessWidget {
  const OfflineNetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NearbyUsersProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Offline Disaster Connect',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
