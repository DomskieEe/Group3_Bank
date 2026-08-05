import 'package:flutter/material.dart';
import '../models/app_user.dart';

class AppState {
  static final AppState instance = AppState._();
  AppState._();

  AppUser? currentUser;
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  void logout() {
    currentUser = null;
  }

  bool get isLoggedIn => currentUser != null;
}
