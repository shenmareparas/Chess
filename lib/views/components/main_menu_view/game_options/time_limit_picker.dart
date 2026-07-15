import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/app_model.dart';
import '../../shared/glass_panel.dart';

class TimeLimitPicker extends StatelessWidget {
  final int? selectedTime;
  final Function(int?)? setTime;

  const TimeLimitPicker({Key? key, this.selectedTime, this.setTime})
      : super(key: key);

  void _showCustomTimerDialog(BuildContext context, AppModel appModel) {
    final isCustom =
        selectedTime != null && ![0, 10, 15, 30].contains(selectedTime);
    final TextEditingController controller = TextEditingController(
      text: isCustom ? selectedTime.toString() : '',
    );
    String? errorMessage;

    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, anim1, anim2) {
        final theme = appModel.theme;
        final primaryColor = theme.lightTile;

        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassPanel(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              color: const Color(0x80201F1F),
              animation: anim1,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: StatefulBuilder(
                  builder: (dialogContext, setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Custom Timer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE5E2E1),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter custom time limit in minutes (1 - 180)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFC3C8C2),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        CupertinoTextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                          cursorColor: primaryColor,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: errorMessage != null
                                  ? Colors.redAccent
                                  : Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          placeholder: 'Minutes',
                          placeholderStyle:
                              const TextStyle(color: Colors.grey, fontSize: 16),
                          onChanged: (_) {
                            if (errorMessage != null) {
                              setState(() {
                                errorMessage = null;
                              });
                            }
                          },
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            // Cancel Button
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Container(
                                  height: 46,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC3C8C2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Set Button
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  final int? val =
                                      int.tryParse(controller.text);
                                  if (val == null) {
                                    setState(() {
                                      errorMessage =
                                          'Please enter a valid number';
                                    });
                                  } else if (val < 1 || val > 180) {
                                    setState(() {
                                      errorMessage =
                                          'Time must be between 1 and 180 minutes';
                                    });
                                  } else {
                                    if (setTime != null) {
                                      setTime!(val);
                                    }
                                    Navigator.pop(dialogContext);
                                  }
                                },
                                child: Container(
                                  height: 46,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F0),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Set',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    final theme = appModel.theme;
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

    final List<MapEntry<int, String>> standardOptions = [
      const MapEntry(0, 'None'),
      const MapEntry(10, '10m'),
      const MapEntry(15, '15m'),
      const MapEntry(30, '30m'),
    ];

    final isCustomSelected = selectedTime != null &&
        !standardOptions.map((e) => e.key).contains(selectedTime);

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
            children: [
              ...standardOptions.map((entry) {
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
              }),
              // Custom option
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCustomTimerDialog(context, appModel),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          isCustomSelected ? activeBgColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCustomSelected ? '${selectedTime}m' : 'Custom',
                      style: TextStyle(
                        color:
                            isCustomSelected ? primaryColor : inactiveTextColor,
                        fontSize: 12,
                        fontWeight: isCustomSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
