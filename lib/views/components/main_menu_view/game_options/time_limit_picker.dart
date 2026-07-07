import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/app_model.dart';

class TimeLimitPicker extends StatelessWidget {
  final int? selectedTime;
  final Function(int?)? setTime;

  TimeLimitPicker({Key? key, this.selectedTime, this.setTime})
      : super(key: key);

  final Map<int, String> timeOptions = const <int, String>{
    0: 'None',
    15: '15m',
    30: '30m',
    45: '45m',
    60: '1h',
  };

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
          'TIME LIMIT',
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: trackBorderColor, width: 1),
          ),
          child: Row(
            children: timeOptions.entries.map((entry) {
              final int value = entry.key;
              final String label = entry.value;
              final bool isSelected = selectedTime == value;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (setTime != null) {
                      setTime!(value);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? activeBgColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? primaryColor : inactiveTextColor,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
