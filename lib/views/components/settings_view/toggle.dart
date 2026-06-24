import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../model/app_model.dart';

class Toggle extends StatelessWidget {
  final String label;
  final bool? toggle;
  final Function(bool)? setFunc;
  final IconData icon;

  const Toggle(
    this.label, {
    Key? key,
    required this.icon,
    this.toggle,
    this.setFunc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context, listen: false);
    final theme = appModel.theme;
    final isActive = toggle ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: isActive ? theme.lightTile : const Color(0xFFC3C8C2).withValues(alpha: 0.6),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                color: Color(0xFFE5E2E1),
              ),
            ),
          ),
          CupertinoSwitch(
            value: isActive,
            activeTrackColor: theme.lightTile,
            inactiveTrackColor: const Color(0xFF353534),
            onChanged: setFunc,
          ),
        ],
      ),
    );
  }
}


