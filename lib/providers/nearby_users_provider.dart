import 'package:flutter/material.dart';

class NearbyUsersProvider extends ChangeNotifier {
  final List<String> nearbyUsers = [];

  void addUser(String user) {
    nearbyUsers.add(user);
    notifyListeners();
  }
}
