import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'login_screen.dart';
import 'home_screen.dart';

// AuthGate watches the auth state and routes accordingly.
// If the user is logged in → HomeScreen
// If not → LoginScreen
// This widget is ConsumerWidget (Riverpod's version of StatelessWidget)
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch(authStateProvider) gives us an AsyncValue<User?>
    // .when() handles the three states: loading, data, error
    return ref.watch(authStateProvider).when(
          loading: () => const Scaffold(
            backgroundColor: Color(0xFF0F0F1A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE94560)),
            ),
          ),
          data: (user) {
            if (user != null) {
              return const HomeScreen();
            }
            return const LoginScreen();
          },
          error: (err, _) => const LoginScreen(),
        );
  }
}
