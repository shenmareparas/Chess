import 'package:flutter/material.dart';
import '../../../model/app_model.dart';
import '../shared/glass_panel.dart';
import 'game_options/ai_difficulty_picker.dart';
import 'game_options/game_mode_picker.dart';
import 'game_options/side_picker.dart';
import 'game_options/time_limit_picker.dart';
import 'game_options/timer_increment_picker.dart';
import 'game_options/timer_mode_picker.dart';

class GameOptions extends StatelessWidget {
  final AppModel appModel;
  final bool hasSavedGame;
  final ScrollController? scrollController;

  const GameOptions(
    this.appModel, {
    Key? key,
    required this.hasSavedGame,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    final buttonsHeight = hasSavedGame ? (54 + 12 + 54) : 54;
    final bottomPaddingVal = safeAreaBottom > 0 ? safeAreaBottom : 20.0;
    final floatingContainerHeight = buttonsHeight + bottomPaddingVal + 24.0;

    const physics = BouncingScrollPhysics();
    final bottomListPadding = floatingContainerHeight + 20.0;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.only(top: 10, bottom: bottomListPadding),
      physics: physics,
      children: [
        // Header Section (Logo, Title, Subtitle)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              Image.asset(
                'assets/images/logo.png',
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
        if (appModel.playerCount == 2) ...[
          GlassPanel(
            child: SidePicker(
              appModel.selectedSideP1,
              appModel.setPlayerSideP1,
              label: 'PLAYER 1 SIDE',
            ),
          ),
          const SizedBox(height: 16),
        ],
        GlassPanel(
          child: TimeLimitPicker(
            selectedTime: appModel.timeLimit,
            setTime: (val) {
              appModel.setTimeLimit(val);
              if (val != null && val > 0) {
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (scrollController != null &&
                      scrollController!.hasClients) {
                    scrollController!.animateTo(
                      scrollController!.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            },
          ),
        ),
        if (appModel.timeLimit > 0) ...[
          const SizedBox(height: 16),
          GlassPanel(
            child: TimerIncrementPicker(
              appModel.timerIncrement,
              (val) {
                appModel.setTimerIncrement(val);
                if (val > 0) {
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (scrollController != null &&
                        scrollController!.hasClients) {
                      scrollController!.animateTo(
                        scrollController!.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                }
              },
            ),
          ),
          if (appModel.timerIncrement > 0) ...[
            const SizedBox(height: 16),
            GlassPanel(
              child: TimerModePicker(
                appModel.timerMode,
                appModel.setTimerMode,
              ),
            ),
          ],
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}
