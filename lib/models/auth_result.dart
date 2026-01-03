import 'user_profile.dart';

class AuthResult {
  final String token;
  final UserProfile user;

  AuthResult({required this.token, required this.user});
}
