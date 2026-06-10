import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  String? name;
  String? phone;

  bool get hasProfile =>
      name != null &&
      phone != null &&
      name!.isNotEmpty &&
      phone!.isNotEmpty;

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    name = prefs.getString('name');
    phone = prefs.getString('phone');

    notifyListeners();
  }

  Future<void> saveProfile({
    required String userName,
    required String phoneNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('name', userName);
    await prefs.setString('phone', phoneNumber);
    await prefs.setBool('profileCreated', true);

    name = userName;
    phone = phoneNumber;

    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    name = null;
    phone = null;

    notifyListeners();
  }
}