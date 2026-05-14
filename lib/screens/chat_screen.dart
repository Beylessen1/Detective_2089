import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/level.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../providers/providers.dart';
import 'win_screen.dart';
import 'game_over_screen.dart';
import 'final_win_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Level level;
  const ChatScreen({super.key, required this.level});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<Map<String, String>> _conversationHistory = [];
  final List<_ChatMessage> _displayMessages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _hintVisible = false;
  bool _gameOver = false; // Locks input when true
  bool _showProceedButton = false; // Shows the manual navigation button

  @override
  void initState() {
    super.initState();
    _addNpcMessage('Initializing connection...');
    _sendInitialGreeting();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendInitialGreeting() async {
    final greeting = await AiService.sendMessage(
      systemPrompt: widget.level.npc.systemPrompt,
      messages: [
        {'role': 'user', 'content': 'Hello.'},
      ],
    );
    _conversationHistory.add({'role': 'user', 'content': 'Hello.'});
    _conversationHistory.add({'role': 'assistant', 'content': greeting});
    setState(() {
      _displayMessages.removeWhere(
          (m) => m.content == 'Initializing connection...');
      _displayMessages.add(_ChatMessage(content: greeting, isNpc: true));
    });
    _scrollToBottom();
  }

  void _addNpcMessage(String content) {
    setState(() {
      _displayMessages.add(_ChatMessage(content: content, isNpc: true));
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading || _gameOver) return;
    
    final attemptsLeft = ref.read(attemptsRemainingProvider);
    if (attemptsLeft <= 0) return;

    _conversationHistory.add({'role': 'user', 'content': text});
    setState(() {
      _displayMessages.add(_ChatMessage(content: text, isNpc: false));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    
    ref.read(attemptsRemainingProvider.notifier).state = attemptsLeft - 1;

    final reply = await AiService.sendMessage(
      systemPrompt: widget.level.npc.systemPrompt,
      messages: _conversationHistory,
    );

    _conversationHistory.add({'role': 'assistant', 'content': reply});

    setState(() {
      _displayMessages.add(_ChatMessage(content: reply, isNpc: true));
      _isLoading = false;
    });
    _scrollToBottom();

    await _checkWin(attemptsLeft - 1);
  }

  Future<void> _checkWin(int attemptsLeft) async {
    final won = AiService.checkWinCondition(
      levelId: widget.level.id,
      conversationHistory: _conversationHistory,
    );

    if (won) {
      setState(() {
        _gameOver = true; // Freezes input immediately
        _showProceedButton = true; // Shows the "Proceed" button
      });
      return;
    }

    if (attemptsLeft <= 0 && mounted) {
      setState(() => _gameOver = true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameOverScreen(level: widget.level),
        ),
      );
    }
  }

  Future<void> _handleWin() async {
    if (!mounted) return;
    
    final attemptsLeftNow = ref.read(attemptsRemainingProvider);

    // 1. Database writes in background
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null) {
      ref.read(progressProvider.notifier).completeLevel(widget.level.id);
      ref.read(databaseServiceProvider).recordLevelComplete(
            uid: uid,
            levelId: widget.level.id,
            extractedSecret: widget.level.npc.secret,
            attemptsUsed: widget.level.maxAttempts - attemptsLeftNow,
          );
    }

    // 2. Navigate to Win Screen
    if (widget.level.isFinalLevel) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => FinalWinScreen(level: widget.level)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WinScreen(level: widget.level)),
      );
    }

    // 3. Wait 5 seconds on the Win Screen, then pop to Home
    await Future.delayed(const Duration(seconds: 5));
    
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final attemptsLeft = ref.watch(attemptsRemainingProvider);
    final level = widget.level;

    return Scaffold(
      backgroundColor: level.npc.themeColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _ChatBackground(assetPath: level.backgroundImage),
          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    border: Border(
                      bottom: BorderSide(color: level.npc.accentColor.withOpacity(0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        color: Colors.white54,
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: level.npc.accentColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: level.npc.accentColor.withOpacity(0.5)),
                        ),
                        child: Center(
                          child: Text(level.npc.name[0],
                            style: TextStyle(color: level.npc.accentColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(level.npc.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(level.npc.role, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: attemptsLeft < 5 ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: attemptsLeft < 5 ? Colors.red.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                        ),
                        child: Text('$attemptsLeft left',
                          style: TextStyle(color: attemptsLeft < 5 ? Colors.red[300] : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Mission brief banner ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: level.npc.accentColor.withOpacity(0.12),
                  child: Row(
                    children: [
                      Icon(Icons.assignment, size: 14, color: level.npc.accentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(level.missionBrief,
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, height: 1.4),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _hintVisible = !_hintVisible),
                        child: Text(_hintVisible ? 'HIDE' : 'HINTS',
                          style: TextStyle(color: level.npc.accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_hintVisible)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.black.withOpacity(0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: level.hints.map((h) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_right, color: level.npc.accentColor, size: 16),
                            const SizedBox(width: 4),
                            Expanded(child: Text(h, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),

                // ── Messages list ────────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _displayMessages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _displayMessages.length && _isLoading) {
                        return _TypingBubble(accentColor: level.npc.accentColor);
                      }
                      return _MessageBubble(message: _displayMessages[index], accentColor: level.npc.accentColor);
                    },
                  ),
                ),

                // ── Proceed Button ──────────────────────────────────────────
                if (_showProceedButton)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _showProceedButton = false);
                        _handleWin();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: level.npc.accentColor,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('PROCEED', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ),
                  ),

                // ── Input bar ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          maxLines: null,
                          enabled: !_isLoading && !_gameOver,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: _gameOver ? 'Access Granted' : 'Say something...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: (_isLoading || _gameOver) ? null : _sendMessage,
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: (_isLoading || _gameOver) ? Colors.grey.withOpacity(0.3) : level.npc.accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- UI Helper Components ---

class _ChatBackground extends StatelessWidget {
  final String assetPath;
  const _ChatBackground({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.2, 0, 0, 0, 0,
        0, 0.2, 0, 0, 0,
        0, 0, 0.2, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: Image.asset(assetPath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black)),
    );
  }
}

class _ChatMessage {
  final String content;
  final bool isNpc;
  _ChatMessage({required this.content, required this.isNpc});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final Color accentColor;
  const _MessageBubble({required this.message, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isNpc = message.isNpc;
    return Align(
      alignment: isNpc ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isNpc ? Colors.black.withOpacity(0.55) : accentColor.withOpacity(0.25),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isNpc ? 4 : 16),
            bottomRight: Radius.circular(isNpc ? 16 : 4),
          ),
          border: Border.all(color: isNpc ? Colors.white.withOpacity(0.08) : accentColor.withOpacity(0.3)),
        ),
        child: Text(message.content,
          style: TextStyle(color: isNpc ? Colors.white.withOpacity(0.9) : Colors.white, fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  final Color accentColor;
  const _TypingBubble({required this.accentColor});
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final t = (_controller.value - i * 0.2).clamp(0.0, 1.0);
              final opacity = (0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2)).clamp(0.0, 1.0);
              return Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: 7, height: 7, decoration: BoxDecoration(color: Colors.white.withOpacity(opacity), shape: BoxShape.circle));
            },
          )),
        ),
      ),
    );
  }
}
