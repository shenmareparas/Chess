import 'package:flutter/material.dart';

import '../../../model/app_model.dart';
import '../shared/glass_panel.dart';
import 'game_options/ai_difficulty_picker.dart';
import 'game_options/game_mode_picker.dart';
import 'game_options/side_picker.dart';
import 'game_options/time_limit_picker.dart';

class GameOptions extends StatelessWidget {
  final AppModel appModel;

  GameOptions(this.appModel);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 10, bottom: 120),
      physics: const BouncingScrollPhysics(),
      children: [
        // Header Section (Logo, Title, Subtitle)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              Image.asset(
                'assets/images/logo2.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              const Text(
                'AI Chess',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                  color: Color(0xFFE5E2E1),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'The Intellectual Arena',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Inter',
                  color: Color(0xFFE5E2E1),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        GlassPanel(
          child: GameModePicker(
            appModel.playerCount,
            appModel.setPlayerCount,
          ),
        ),
        const SizedBox(height: 16),
        if (appModel.playerCount == 1) ...[
          GlassPanel(
            child: AIDifficultyPicker(
              appModel.aiDifficulty,
              appModel.setAIDifficulty,
            ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            child: SidePicker(
              appModel.selectedSide,
              appModel.setPlayerSide,
            ),
          ),
          const SizedBox(height: 16),
        ],
        GlassPanel(
          child: TimeLimitPicker(
            selectedTime: appModel.timeLimit,
            setTime: appModel.setTimeLimit,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
