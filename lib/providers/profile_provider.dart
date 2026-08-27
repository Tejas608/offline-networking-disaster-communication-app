import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  String? name;
  String? phone;

  bool get hasProfile =>
      name != null &&
      phone != null &&
      name!.trim().isNotEmpty &&
      phone!.trim().isNotEmpty;

  Future<void> loadProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    name = prefs.getString('name');
    phone = prefs.getString('phone');

    notifyListeners();
  }

  Future<void> saveProfile({
    required String userName,
    required String phoneNumber,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('name', userName.trim());

    await prefs.setString('phone', phoneNumber.trim());

    await prefs.setBool('profileCreated', true);

    name = userName.trim();
    phone = phoneNumber.trim();

    notifyListeners();
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Keep localUserId and SQLite data.
    await prefs.remove('name');
    await prefs.remove('phone');
    await prefs.remove('profileCreated');

    name = null;
    phone = null;

    notifyListeners();
  }
}
