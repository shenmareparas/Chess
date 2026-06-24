import 'package:flutter/cupertino.dart';
import '../../../shared/glass_panel.dart';

class RoundedIconButton extends StatelessWidget {
  final IconData icon;
  final void Function()? onPressed;

  const RoundedIconButton(this.icon, {this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: GlassPanel(
        padding: EdgeInsets.zero,
        borderRadius: 14,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: Icon(icon, color: const Color(0xffffffff), size: 22),
        ),
      ),
    );
  }
}
