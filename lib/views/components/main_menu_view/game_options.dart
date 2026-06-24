import 'package:flutter/material.dart';
import '../../../logic/game_state_storage.dart';
import '../../../model/app_model.dart';
import '../shared/glass_panel.dart';
import 'game_options/ai_difficulty_picker.dart';
import 'game_options/game_mode_picker.dart';
import 'game_options/side_picker.dart';
import 'game_options/time_limit_picker.dart';

class GameOptions extends StatelessWidget {
  final AppModel appModel;
  final ScrollController? scrollController;

  const GameOptions(this.appModel, {Key? key, this.scrollController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: GameStateStorage.hasSavedGame(),
      builder: (context, snapshot) {
        final hasSaved = snapshot.data ?? false;

        final screenHeight = MediaQuery.of(context).size.height;
        final safeAreaTop = MediaQuery.of(context).padding.top;
        final safeAreaBottom = MediaQuery.of(context).padding.bottom;

        final buttonsHeight = hasSaved ? (54 + 12 + 54) : 54;
        final bottomPaddingVal = safeAreaBottom > 0 ? safeAreaBottom : 20.0;
        final floatingContainerHeight = buttonsHeight + bottomPaddingVal + 24.0;

        final isOnePlayer = appModel.playerCount == 1;
        final gapsHeight = isOnePlayer ? 98.0 : 66.0;
        final pickersHeight = isOnePlayer ? 416.0 : 208.0;
        final contentHeight = 180.0 + gapsHeight + pickersHeight;

        final availableHeight =
            screenHeight - safeAreaTop - floatingContainerHeight;
        final fits = contentHeight < availableHeight;

        final physics = fits
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics();
        final bottomListPadding =
            fits ? 20.0 : (floatingContainerHeight + 20.0);

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
            GlassPanel(
              child: TimeLimitPicker(
                selectedTime: appModel.timeLimit,
                setTime: appModel.setTimeLimit,
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
