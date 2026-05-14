import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/level.dart';
import 'chat_screen.dart';

class IntroVideoScreen extends StatefulWidget {
  final Level level;
  const IntroVideoScreen({super.key, required this.level});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _navigationTriggered = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _showSkip = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // ── KEY FIX: defer everything until after the first frame ────────────
    // _initVideo() may call _goToChat() synchronously (empty path),
    // which calls Navigator.pushReplacement. Doing that inside initState
    // triggers "setState/markNeedsBuild called during build" because the
    // navigator is still locked. addPostFrameCallback runs after the frame
    // is fully committed, so navigation is always safe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initVideo();
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSkip = true);
    });

    // Hard timeout
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_navigationTriggered) _goToChat();
    });
  }

  Future<void> _initVideo() async {
    final path = widget.level.introVideo;

    if (path.isEmpty) {
      debugPrint('[IntroVideoScreen] introVideo is empty — skipping to chat');
      _goToChat();
      return;
    }

    debugPrint('[IntroVideoScreen] Loading: $path');

    try {
      final controller = VideoPlayerController.asset(path);
      _controller = controller;

      await controller.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('initialize() timed out'),
      );

      if (!mounted) return;

      if (controller.value.hasError) {
        throw Exception(controller.value.errorDescription);
      }

      controller.addListener(_onVideoEvent);
      setState(() => _initialized = true);

      await controller.play();
      _fadeController.forward();
    } catch (e) {
      debugPrint('[IntroVideoScreen] Error: $e');
      _controller?.dispose();
      _controller = null;
      if (mounted) _goToChat();
    }
  }

  void _onVideoEvent() {
    final ctrl = _controller;
    if (ctrl == null || _navigationTriggered) return;

    if (ctrl.value.hasError) {
      ctrl.removeListener(_onVideoEvent);
      _goToChat();
      return;
    }

    if (ctrl.value.isInitialized &&
        !ctrl.value.isPlaying &&
        !ctrl.value.isBuffering &&
        ctrl.value.duration > Duration.zero &&
        ctrl.value.position >= ctrl.value.duration) {
      ctrl.removeListener(_onVideoEvent);
      _goToChat();
    }
  }

  void _goToChat() {
    if (_navigationTriggered) return;
    _navigationTriggered = true;
    if (!mounted) return;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => ChatScreen(level: widget.level),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoEvent);
    _controller?.dispose();
    _fadeController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video or spinner
          if (_initialized && _controller != null)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white24,
                strokeWidth: 1.5,
              ),
            ),

          // Vignette
          if (_initialized)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.45),
                    ],
                  ),
                ),
              ),
            ),

          // SKIP button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: AnimatedOpacity(
              opacity: _showSkip ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: GestureDetector(
                onTap: _goToChat,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SKIP',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.skip_next_rounded,
                        size: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
