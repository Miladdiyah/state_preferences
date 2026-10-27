import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UserProvider extends InheritedWidget {
  final User user;
  final Function(User) updateUser;
  final VoidCallback logout;
  final bool isLoading;
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  final int visitCount;
  final List<String> favorites; // LATIHAN 3
  final Future<bool> Function(String) addFavorite; // LATIHAN 3
  final Future<void> Function(String) removeFavorite; // LATIHAN 3

  const UserProvider({
    super.key,
    required this.user,
    required this.updateUser,
    required this.logout,
    required this.isLoading,
    required this.isDarkMode,
    required this.toggleTheme,
    required this.visitCount,
    required this.favorites, // LATIHAN 3
    required this.addFavorite, // LATIHAN 3
    required this.removeFavorite, // LATIHAN 3
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
        oldWidget.isDarkMode != isDarkMode ||
        oldWidget.visitCount != visitCount ||
        oldWidget.favorites != favorites; // LATIHAN 3
  }
}

class UserProviderWrapper extends StatefulWidget {
  final Widget child;

  const UserProviderWrapper({super.key, required this.child});

  @override
  State<UserProviderWrapper> createState() => _UserProviderWrapperState();
}

class _UserProviderWrapperState extends State<UserProviderWrapper> {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false;
  int _visitCount = 0;
  List<String> _favorites = []; // LATIHAN 3

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final isDarkMode = prefs.getBool('is_dark_mode') ?? false;

    final visitCount = (prefs.getInt('visit_count') ?? 0) + 1;
    await prefs.setInt('visit_count', visitCount);

    // LATIHAN 3: muat daftar favorit
    final favorites = prefs.getStringList('favorites') ?? [];

    setState(() {
      _user = User(name: name, email: email, isLoggedIn: isLoggedIn);
      _isDarkMode = isDarkMode;
      _visitCount = visitCount;
      _favorites = favorites; // LATIHAN 3
      _isLoading = false;
    });
  }

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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);

    setState(() {
      _user = _user.copyWith(name: '', isLoggedIn: false);
    });
  }

  Future<void> _toggleTheme() async {
    final newValue = !_isDarkMode;
    setState(() => _isDarkMode = newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', newValue);
  }

  // LATIHAN 3: tambah favorit (return false jika kosong atau duplikat)
  Future<bool> _addFavorite(String item) async {
    final value = item.trim();
    if (value.isEmpty) return false;
    if (_favorites.any((f) => f.toLowerCase() == value.toLowerCase())) {
      return false;
    }

    final newList = [..._favorites, value];
    setState(() => _favorites = newList);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', newList);
    return true;
  }

  // LATIHAN 3: hapus favorit
  Future<void> _removeFavorite(String item) async {
    final newList = _favorites.where((f) => f != item).toList();
    setState(() => _favorites = newList);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', newList);
  }

  @override
  Widget build(BuildContext context) {
    return UserProvider(
      user: _user,
      updateUser: _updateUser,
      logout: _logout,
      isLoading: _isLoading,
      isDarkMode: _isDarkMode,
      toggleTheme: _toggleTheme,
      visitCount: _visitCount,
      favorites: _favorites, // LATIHAN 3
      addFavorite: _addFavorite, // LATIHAN 3
      removeFavorite: _removeFavorite, // LATIHAN 3
      child: widget.child,
    );
  }
}
