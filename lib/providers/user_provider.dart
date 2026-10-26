import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UserProvider extends InheritedWidget {
  final User user;
  final Function(User) updateUser;
  final VoidCallback logout;
  final bool isLoading;
  final bool isDarkMode; // LATIHAN 1
  final VoidCallback toggleTheme; // LATIHAN 1

  const UserProvider({
    super.key,
    required this.user,
    required this.updateUser,
    required this.logout,
    required this.isLoading,
    required this.isDarkMode, // LATIHAN 1
    required this.toggleTheme, // LATIHAN 1
    required super.child,
  });

  static UserProvider of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<UserProvider>();
    assert(provider != null, 'UserProvider tidak ditemukan di context');
    return provider!;
  }

  @override
  bool updateShouldNotify(UserProvider oldWidget) {
    return oldWidget.user != user ||
        oldWidget.isLoading != isLoading ||
        oldWidget.isDarkMode != isDarkMode; // LATIHAN 1
  }
}

// StatefulWidget yang membungkus InheritedWidget
class UserProviderWrapper extends StatefulWidget {
  final Widget child;

  const UserProviderWrapper({super.key, required this.child});

  @override
  State<UserProviderWrapper> createState() => _UserProviderWrapperState();
}

class _UserProviderWrapperState extends State<UserProviderWrapper> {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false; // LATIHAN 1

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Memuat data dari SharedPreferences
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final isDarkMode = prefs.getBool('is_dark_mode') ?? false; // LATIHAN 1

    setState(() {
      _user = User(name: name, email: email, isLoggedIn: isLoggedIn);
      _isDarkMode = isDarkMode; // LATIHAN 1
      _isLoading = false;
    });
  }

  // Menyimpan data user ke SharedPreferences
  Future<void> _updateUser(User newUser) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);

    setState(() {
      _user = newUser;
      _isLoading = false;
    });
  }

  // Logout: hapus data user (kecuali email)
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);

    setState(() {
      _user = _user.copyWith(name: '', isLoggedIn: false);
    });
  }

  // LATIHAN 1: toggle tema dan simpan ke SharedPreferences
  Future<void> _toggleTheme() async {
    final newValue = !_isDarkMode;
    setState(() => _isDarkMode = newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', newValue);
  }

  @override
  Widget build(BuildContext context) {
    return UserProvider(
      user: _user,
      updateUser: _updateUser,
      logout: _logout,
      isLoading: _isLoading,
      isDarkMode: _isDarkMode, // LATIHAN 1
      toggleTheme: _toggleTheme, // LATIHAN 1
      child: widget.child,
    );
  }
}
