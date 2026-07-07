import 'dart:math' as math;
import 'package:flutter/cupertino.dart';

class BottomPadding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double bottomPadding = MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: math.max(16.0, bottomPadding),
    );
  }
}
