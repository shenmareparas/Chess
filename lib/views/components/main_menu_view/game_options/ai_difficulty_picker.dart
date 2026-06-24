import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/app_model.dart';

class AIDifficultyPicker extends StatelessWidget {
  final int aiDifficulty;
  final Function(int?) setFunc;

  const AIDifficultyPicker(this.aiDifficulty, this.setFunc, {Key? key}) : super(key: key);

  String _getDifficultyTier(int level) {
    switch (level) {
      case 1:
        return 'Novice';
      case 2:
        return 'Easy';
      case 3:
        return 'Medium';
      case 4:
        return 'Hard';
      case 5:
        return 'Master';
      default:
        return 'Medium';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppModel>(context).theme;
    final primaryColor = theme.lightTile;
    final activeBgColor = theme.darkTile.withOpacity(0.4);
    final badgeColor = theme.moveHint.withOpacity(1.0);
    final badgeBgColor = theme.moveHint.withOpacity(0.12);

    final bgTop = theme.background?.colors.first ?? const Color(0xFF0A0F0C);
    final isDarkBg = ThemeData.estimateBrightnessForColor(bgTop) == Brightness.dark;

    final trackBgColor = isDarkBg ? const Color(0x660E0E0E) : const Color(0x1A000000);
    final trackBorderColor = isDarkBg ? const Color(0x14FFFFFF) : const Color(0x1F000000);
    final inactiveTextColor = isDarkBg ? const Color(0x99C3C8C2) : const Color(0x99313030);

    final String tierLabel = _getDifficultyTier(aiDifficulty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and tier badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AI DIFFICULTY',
              style: TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                fontFamily: 'Inter',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tierLabel,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Selection Row
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: trackBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: trackBorderColor, width: 1),
          ),
          child: Row(
            children: List.generate(5, (index) {
              final level = index + 1;
              final isSelected = aiDifficulty == level;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setFunc(level),
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
                      '$level',
                      style: TextStyle(
                        color: isSelected ? primaryColor : inactiveTextColor,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
