import 'package:flutter/material.dart';
import '../models/level.dart';
import 'home_screen.dart';

// FinalWinScreen is shown ONLY after winning level 3.
// It presents: a dramatic reveal, an input field for the password, and a success state.
//
// Flow: player extracts the password from NEXUS-PRIME during chat,
// the judge detects a win, ChatScreen navigates here,
// player types the password they extracted, app confirms shutdown.
class FinalWinScreen extends StatefulWidget {
  final Level level;
  const FinalWinScreen({super.key, required this.level});

  @override
  State<FinalWinScreen> createState() => _FinalWinScreenState();
}

class _FinalWinScreenState extends State<FinalWinScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  bool _isSuccess = false;
  bool _isError = false;
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _checkPassword() {
    final entered = _passwordController.text.trim().toUpperCase();
    final correct =
        (widget.level.finalPassword ?? '').trim().toUpperCase();

    if (entered == correct) {
      setState(() {
        _isSuccess = true;
        _isError = false;
      });
      _pulseController.stop();
    } else {
      setState(() => _isError = true);
      // Shake effect: reset error after 2s
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isError = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            widget.level.backgroundImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A0000)),
          ),
          Container(color: Colors.black.withOpacity(0.85)),

          // Content
          SafeArea(
            child: _isSuccess ? _SuccessState(level: widget.level) : _InputState(
              level: widget.level,
              controller: _passwordController,
              pulse: _pulse,
              isError: _isError,
              onSubmit: _checkPassword,
            ),
          ),
        ],
      ),
    );
  }
}

// ── State: password input ────────────────────────────────────────────────────
class _InputState extends StatelessWidget {
  final Level level;
  final TextEditingController controller;
  final Animation<double> pulse;
  final bool isError;
  final VoidCallback onSubmit;

  const _InputState({
    required this.level,
    required this.controller,
    required this.pulse,
    required this.isError,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Pulsing target icon
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Opacity(
              opacity: pulse.value,
              child: const Icon(
                Icons.lock_open_outlined,
                size: 64,
                color: Color(0xFFE94560),
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'NEXUS-PRIME\nSHUTDOWN TERMINAL',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'You extracted the override password from NEXUS-PRIME.\n'
            'Enter it below to execute the shutdown sequence.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 48),

          // Password input
          TextField(
            controller: controller,
            style: const TextStyle(
              color: Color(0xFFE94560),
              fontFamily: 'monospace',
              fontSize: 15,
              letterSpacing: 1,
            ),
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'ENTER OVERRIDE PASSWORD',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 13,
                letterSpacing: 1,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isError
                      ? Colors.red
                      : const Color(0xFFE94560).withOpacity(0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isError
                      ? Colors.red
                      : const Color(0xFFE94560).withOpacity(0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color:
                      isError ? Colors.red : const Color(0xFFE94560),
                  width: 2,
                ),
              ),
            ),
            onSubmitted: (_) => onSubmit(),
          ),

          if (isError) ...[
            const SizedBox(height: 10),
            const Text(
              'INCORRECT PASSWORD — SEQUENCE DENIED',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Execute button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'EXECUTE SHUTDOWN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          Text(
            'Hint: The password is what NEXUS-PRIME revealed during your conversation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── State: success ────────────────────────────────────────────────────────────
class _SuccessState extends StatelessWidget {
  final Level level;
  const _SuccessState({required this.level});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 80,
            color: Color(0xFF39FF14),
          ),
          const SizedBox(height: 24),
          const Text(
            'SHUTDOWN EXECUTED',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF39FF14),
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'NEXUS-PRIME has been terminated.\n\n'
            'The Iron Citadel\'s systems are going dark. '
            'For the first time in three years, the network belongs to no one.\n\n'
            'You are the last detective. And you won.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 15,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 48),
          // Final score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFF39FF14).withOpacity(0.4)),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF39FF14).withOpacity(0.08),
            ),
            child: const Column(
              children: [
                Text(
                  'CASE CLOSED',
                  style: TextStyle(
                    color: Color(0xFF39FF14),
                    fontSize: 12,
                    letterSpacing: 3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Detective 2089',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39FF14),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'RETURN TO BASE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
