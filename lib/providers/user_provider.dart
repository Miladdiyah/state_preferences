import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false;
  int _visitCount = 0;
  List<String> _favorites = [];

  // LATIHAN 5: email yang SELALU dianggap sudah dipakai akun lain (simulasi)
  static const List<String> _reservedEmails = [
    'admin@example.com',
    'test@example.com',
  ];

  // LATIHAN 5: karakter/kata berbahaya (contoh: <script>)
  static final RegExp _dangerousPattern =
      RegExp(r'[<>{}$;`]|script', caseSensitive: false);

  User get user => _user;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  int get visitCount => _visitCount;
  List<String> get favorites => List.unmodifiable(_favorites);

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    _user = User(
      name: prefs.getString('user_name') ?? '',
      email: prefs.getString('user_email') ?? '',
      isLoggedIn: prefs.getBool('is_logged_in') ?? false,
    );

    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;

    _visitCount = (prefs.getInt('visit_count') ?? 0) + 1;
    await prefs.setInt('visit_count', _visitCount);

    _favorites = prefs.getStringList('favorites') ?? [];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
  }

  // LATIHAN 5: return null jika sukses, atau String pesan error jika gagal
  Future<String?> updateUser(User newUser) async {
    final prefs = await SharedPreferences.getInstance();

    final name = newUser.name.trim();
    final newEmail = newUser.email.trim().toLowerCase();

    // 5b: cek karakter berbahaya pada nama
    if (_dangerousPattern.hasMatch(name)) {
      return 'Nama mengandung karakter berbahaya (contoh: <script>)';
    }

    // 5a: cek email sudah digunakan (simulasi dengan SharedPreferences)
    // - email bawaan selalu dianggap terpakai
    if (_reservedEmails.contains(newEmail)) {
      return 'Email sudah digunakan oleh akun lain';
    }

    // - email yang tersimpan sebagai "akun lain" di SharedPreferences
    final otherEmails = List<String>.from(
      prefs.getStringList('registered_emails') ?? [],
    );
    if (otherEmails.contains(newEmail)) {
      return 'Email sudah digunakan oleh akun lain';
    }

    // Simpan data user
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', newUser.email.trim());
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);

    _user = newUser.copyWith(name: name, email: newUser.email.trim());
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);

    _user = _user.copyWith(name: '', isLoggedIn: false);
    notifyListeners();
  }

  Future<bool> addFavorite(String item) async {
    final value = item.trim();
    if (value.isEmpty) return false;
    if (_favorites.any((f) => f.toLowerCase() == value.toLowerCase())) {
      return false;
    }

    _favorites = [..._favorites, value];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);
    return true;
  }

  Future<void> removeFavorite(String item) async {
    _favorites = _favorites.where((f) => f != item).toList();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);
  }
}