import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/app_model.dart';
import '../../../../model/player.dart';

class SidePicker extends StatelessWidget {
  final Player playerSide;
  final Function(Player?) setFunc;

  const SidePicker(this.playerSide, this.setFunc, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppModel>(context).theme;
    final primaryColor = theme.lightTile;
    final activeBgColor = theme.darkTile.withOpacity(0.4);

    final bgTop = theme.background?.colors.first ?? const Color(0xFF0A0F0C);
    final isDarkBg =
        ThemeData.estimateBrightnessForColor(bgTop) == Brightness.dark;

    final trackBgColor =
        isDarkBg ? const Color(0x660E0E0E) : const Color(0x1A000000);
    final trackBorderColor =
        isDarkBg ? const Color(0x14FFFFFF) : const Color(0x1F000000);
    final inactiveTextColor =
        isDarkBg ? const Color(0x80C3C8C2) : const Color(0x99313030);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHOOSE SIDE',
          style: TextStyle(
            color: primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: trackBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: trackBorderColor, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSideSegment(
                  label: 'White',
                  isSelected: playerSide == Player.player1,
                  primaryColor: primaryColor,
                  activeBgColor: activeBgColor,
                  inactiveTextColor: inactiveTextColor,
                  onTap: () => setFunc(Player.player1),
                ),
              ),
              Expanded(
                child: _buildSideSegment(
                  label: 'Black',
                  isSelected: playerSide == Player.player2,
                  primaryColor: primaryColor,
                  activeBgColor: activeBgColor,
                  inactiveTextColor: inactiveTextColor,
                  onTap: () => setFunc(Player.player2),
                ),
              ),
              Expanded(
                child: _buildSideSegment(
                  label: 'Random',
                  isSelected: playerSide == Player.random,
                  primaryColor: primaryColor,
                  activeBgColor: activeBgColor,
                  inactiveTextColor: inactiveTextColor,
                  onTap: () => setFunc(Player.random),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSideSegment({
    required String label,
    required bool isSelected,
    required Color primaryColor,
    required Color activeBgColor,
    required Color inactiveTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : inactiveTextColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
