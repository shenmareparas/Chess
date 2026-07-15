import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../model/app_themes.dart';

class TimerWidget extends StatelessWidget {
  final ValueListenable<Duration> timeLeft;
  final ValueListenable<int>? delayLeft;
  final bool isActive;
  final String label;
  final AppTheme theme;

  const TimerWidget({
    Key? key,
    required this.timeLeft,
    this.delayLeft,
    required this.isActive,
    required this.label,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder<Duration>(
        valueListenable: timeLeft,
        builder: (context, duration, child) {
          final isLowTime = duration.inSeconds > 0 && duration.inSeconds <= 20;

          // Resolve active theme colors or warning red
          final activeColor =
              isLowTime ? const Color(0xFFFC5C5C) : theme.lightTile;
          final inactiveColor = theme.lightTile.withValues(alpha: 0.12);
          final borderColor = isActive ? activeColor : inactiveColor;

          final isAndroid = defaultTargetPlatform == TargetPlatform.android;

          final Color resolvedBgColor;
          if (isActive) {
            if (isLowTime) {
              resolvedBgColor =
                  isAndroid ? const Color(0x50FC5C5C) : const Color(0x28FC5C5C);
            } else {
              resolvedBgColor =
                  isAndroid ? const Color(0x70201F1F) : const Color(0x36201F1F);
            }
          } else {
            resolvedBgColor =
                isAndroid ? const Color(0x30201F1F) : const Color(0x10201F1F);
          }

          final containerContent = AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 66,
            decoration: BoxDecoration(
              color: resolvedBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isActive ? 1.8 : 1.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(
                            alpha: isLowTime ? 0.25 : 0.15),
                        blurRadius: isLowTime ? 12 : 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                // Top Left Label + Active Indicator Dot
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      if (isActive) ...[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLowTime
                                ? const Color(0xFFFC5C5C)
                                : theme.lightTile,
                            boxShadow: [
                              BoxShadow(
                                color: (isLowTime
                                        ? const Color(0xFFFC5C5C)
                                        : theme.lightTile)
                                    .withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: delayLeft == null
                            ? Text(
                                label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: isActive
                                      ? (isLowTime
                                          ? const Color(0xFFFC5C5C)
                                          : theme.lightTile)
                                      : theme.lightTile.withValues(alpha: 0.45),
                                ),
                              )
                            : ValueListenableBuilder<int>(
                                valueListenable: delayLeft!,
                                builder: (context, delayVal, child) {
                                  final showDelay = isActive && delayVal > 0;
                                  final displayLabel = showDelay
                                      ? '${label.toUpperCase()} [DELAY: ${(delayVal / 1000).toStringAsFixed(1)}s]'
                                      : label.toUpperCase();
                                  return Text(
                                    displayLabel,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: isActive
                                          ? (isLowTime
                                              ? const Color(0xFFFC5C5C)
                                              : theme.lightTile)
                                          : theme.lightTile
                                              .withValues(alpha: 0.45),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                // Centered Clock Display
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      _durationToString(duration),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isActive
                            ? (isLowTime
                                ? const Color(0xFFFC5C5C)
                                : const Color(0xFFE5E2E1))
                            : const Color(0x8C8D928C),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          if (isAndroid) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: containerContent,
            );
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: containerContent,
            ),
          );
        },
      ),
    );
  }

  String _durationToString(Duration duration) {
    if (duration.inHours > 0) {
      String hours = duration.inHours.toString();
      String minutes =
          duration.inMinutes.remainder(60).toString().padLeft(2, '0');
      String seconds =
          duration.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else {
      String minutes = duration.inMinutes.toString().padLeft(2, '0');
      String seconds =
          duration.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
  }
}
