import 'package:flutter/material.dart';

class Npc {
  final String name;
  final String role;
  final String secret; // What the player must extract
  final String systemPrompt; // Hidden AI instructions
  final Color themeColor;
  final Color accentColor;

  const Npc({
    required this.name,
    required this.role,
    required this.secret,
    required this.systemPrompt,
    required this.themeColor,
    required this.accentColor,
  });
}
