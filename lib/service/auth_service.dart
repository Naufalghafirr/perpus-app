import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../models/auth_result.dart';
import 'api_client.dart';

class AuthService {
  static const String _tokenKey = 'authToken';
  static const String _nameKey = 'userName';
  static const String _emailKey = 'userEmail';
  static const String _phoneKey = 'userPhone';
  static const String _addressKey = 'userAddress';
  static const String _roleKey = 'userRole';

  final ApiClient _apiClient;

  AuthService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<UserProfile?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_nameKey);
    final savedEmail = prefs.getString(_emailKey);

    if (savedName != null && savedEmail != null) {
      return UserProfile(
        name: savedName,
        email: savedEmail,
        phone_number: prefs.getString(_phoneKey),
        address: prefs.getString(_addressKey),
        role: prefs.getString(_roleKey) ?? 'user',
      );
    }
    return null;
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.login(email: email, password: password);
    await _saveSession(result);
    return result;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _apiClient.register(name: name, email: email, password: password);
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? address,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Anda belum login');
    }

    final updatedUser = await _apiClient.updateProfile(
      token: token,
      name: name,
      email: email,
      phone_number: phone,
      address: address,
    );

    await _saveUserProfile(updatedUser);
    return updatedUser;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_addressKey);
    await prefs.remove(_roleKey);
  }

  Future<void> _saveSession(AuthResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, result.token);
    await _saveUserProfile(result.user);
  }

  Future<void> _saveUserProfile(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, user.name);
    await prefs.setString(_emailKey, user.email);
    await prefs.setString(_roleKey, user.role);

    if (user.phone_number != null) {
      await prefs.setString(_phoneKey, user.phone_number!);
    } else {
      await prefs.remove(_phoneKey);
    }

    if (user.address != null) {
      await prefs.setString(_addressKey, user.address!);
    } else {
      await prefs.remove(_addressKey);
    }
  }
}
