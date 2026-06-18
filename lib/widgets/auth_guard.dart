import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth_prompt_screen.dart';

/// Wraps a widget that requires authentication.
/// If the user is not logged in, shows [AuthPromptScreen] instead.
class AuthGuard extends StatelessWidget {
  final WidgetBuilder builder;

  const AuthGuard({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (AuthService.isLoggedIn) {
      return builder(context);
    }
    return const AuthPromptScreen();
  }

  /// Call this from a button handler. Returns true if the user is logged in.
  /// If not, navigates to the auth prompt so they can sign up.
  static bool requireAuth(BuildContext context) {
    if (AuthService.isLoggedIn) return true;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthPromptScreen()),
    );
    return false;
  }
}
