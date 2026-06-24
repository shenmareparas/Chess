import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/app_model.dart';
import '../../../../model/app_themes.dart';

class GameModePicker extends StatelessWidget {
  final int playerCount;
  final Function(int?) setFunc;

  const GameModePicker(this.playerCount, this.setFunc, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppModel>(context).theme;
    final primaryColor = theme.lightTile;
    final activeBgColor = theme.darkTile.withValues(alpha: 0.4);

    final bgTop = theme.background?.colors.first ?? const Color(0xFF0A0F0C);
    final isDarkBg =
        ThemeData.estimateBrightnessForColor(bgTop) == Brightness.dark;

    final trackBgColor =
        isDarkBg ? const Color(0x660E0E0E) : const Color(0x1A000000);
    final trackBorderColor =
        isDarkBg ? const Color(0x14FFFFFF) : const Color(0x1F000000);
    final inactiveTextColor =
        isDarkBg ? const Color(0x99C3C8C2) : const Color(0x99313030);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GAME MODE',
          style: TextStyle(
            color: primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: trackBgColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: trackBorderColor, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildButton(
                  context: context,
                  label: 'One Player',
                  isSelected: playerCount == 1,
                  theme: theme,
                  primaryColor: primaryColor,
                  activeBgColor: activeBgColor,
                  inactiveTextColor: inactiveTextColor,
                  onTap: () => setFunc(1),
                ),
              ),
              Expanded(
                child: _buildButton(
                  context: context,
                  label: 'Two Player',
                  isSelected: playerCount == 2,
                  theme: theme,
                  primaryColor: primaryColor,
                  activeBgColor: activeBgColor,
                  inactiveTextColor: inactiveTextColor,
                  onTap: () => setFunc(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required AppTheme theme,
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
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : inactiveTextColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
