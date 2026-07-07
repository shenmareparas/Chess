import 'package:flutter/material.dart';

class AppTheme {
  String? name;
  LinearGradient? background;
  Color lightTile;
  Color darkTile;
  Color moveHint;
  Color checkHint;
  Color latestMove;
  Color border;
  Color notation;

  AppTheme({
    this.name,
    this.background,
    this.lightTile = const Color(0xFFC9B28F),
    this.darkTile = const Color(0xFF69493b),
    this.moveHint = const Color(0xdd5c81c4),
    this.latestMove = const Color(0xccc47937),
    this.checkHint = const Color(0x88ff0000),
    this.border = const Color(0xffffffff),
    this.notation = const Color(0xFFE0E0E0),
  });
}

final List<AppTheme> themeList = _buildThemeList();

List<AppTheme> _buildThemeList() {
  var list = <AppTheme>[
    AppTheme(
      name: 'Forest Mint',
      background: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F1B15),
          Color(0xFF0A0F0D),
        ],
      ),
      lightTile: const Color(0xFFC2D9C8),
      darkTile: const Color(0xFF43614E),
      moveHint: const Color(0xAAE0B634),
      checkHint: const Color(0xCCFF5555),
      latestMove: const Color(0xAAFFDF7A),
      border: const Color(0xFF0A0F0D),
      notation: const Color(0xFFC2D9C8),
    ),
    AppTheme(
      name: 'Midnight Slate',
      background: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF141923),
          Color(0xFF0B0E14),
        ],
      ),
      lightTile: const Color(0xFFD2D8E0),
      darkTile: const Color(0xFF4C5E77),
      moveHint: const Color(0xAA5B9CF8),
      checkHint: const Color(0xCCFF5555),
      latestMove: const Color(0xAA9EC4FA),
      border: const Color(0xFF0B0E14),
      notation: const Color(0xFFD2D8E0),
    ),
    AppTheme(
      name: 'Amoled Carbon',
      background: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF000000),
          Color(0xFF000000),
        ],
      ),
      lightTile: const Color(0xFFA4AFBA),
      darkTile: const Color(0xFF383F49),
      moveHint: const Color(0xAA4B5563),
      checkHint: const Color(0xCCFF5555),
      latestMove: const Color(0xAA9CA3AF),
      border: const Color(0xFF1F2937),
      notation: const Color(0xFFFFFFFF),
    ),
    AppTheme(
      name: 'Royal Velvet',
      background: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1E0E18),
          Color(0xFF0F070C),
        ],
      ),
      lightTile: const Color(0xFFE5B2B8),
      darkTile: const Color(0xFF8C3E56),
      moveHint: const Color(0xAAE9C349),
      checkHint: const Color(0xCCFF5555),
      latestMove: const Color(0xAAFFE088),
      border: const Color(0xFF0F070C),
      notation: const Color(0xFFE5B2B8),
    ),
    AppTheme(
      name: 'Warm Walnut',
      background: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF22150E),
          Color(0xFF130B07),
        ],
      ),
      lightTile: const Color(0xFFE2C4A2),
      darkTile: const Color(0xFF86553B),
      moveHint: const Color(0xAAC67C28),
      checkHint: const Color(0xCCFF5555),
      latestMove: const Color(0xAAFFD15C),
      border: const Color(0xFF130B07),
      notation: const Color(0xFFE2C4A2),
    ),
    AppTheme(
      name: 'Jargon Jade',
      background: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF04191C),
          Color(0xFF020C0E),
        ],
      ),
      lightTile: const Color(0xFF5C9E92),
      darkTile: const Color(0xFF1B555C),
      moveHint: const Color(0xAA8AE84A),
      checkHint: const Color(0xCCFF5555),
      latestMove: const Color(0xAA79D2FF),
      border: const Color(0xFF020C0E),
      notation: const Color(0xFF5C9E92),
    ),
    AppTheme(
      name: 'Winter Glacier',
      background: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF131E29),
          Color(0xFF0B1118),
        ],
      ),
      lightTile: const Color(0xFFC9DCE8),
      darkTile: const Color(0xFF557C96),
      moveHint: const Color(0xAA5B9CF8),
      checkHint: const Color(0xCCFF5555),
      latestMove: const Color(0xAA9EC4FA),
      border: const Color(0xFF0B1118),
      notation: const Color(0xFFC9DCE8),
    ),
    AppTheme(
      name: 'Oceanic Breeze',
      background: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF091624),
          Color(0xFF040A10),
        ],
      ),
      lightTile: const Color(0xFFA5C3E2),
      darkTile: const Color(0xFF335880),
      moveHint: const Color(0xAA00E5FF),
      checkHint: const Color(0xCCFF5555),
      latestMove: const Color(0xAAFFE088),
      border: const Color(0xFF040A10),
      notation: const Color(0xFFA5C3E2),
    ),
  ];
  list.sort((a, b) => a.name?.compareTo(b.name ?? "") ?? 0);
  return list;
}
