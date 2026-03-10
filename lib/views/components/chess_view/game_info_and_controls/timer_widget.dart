import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../shared/text_variable.dart';

class TimerWidget extends StatelessWidget {
  final ValueListenable<Duration> timeLeft;
  final Color color;

  TimerWidget({required this.timeLeft, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder<Duration>(
        valueListenable: timeLeft,
        builder: (context, duration, child) {
          return Container(
            height: 60,
            child: Center(
              child: TextRegular(_durationToString(duration)),
            ),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(14),
              color: Color(0x20000000),
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
    } else if (duration.inMinutes > 0) {
      String minutes = duration.inMinutes.toString();
      String seconds =
          duration.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    } else {
      String seconds = duration.inSeconds.toString();
      return '$seconds';
    }
  }
}
