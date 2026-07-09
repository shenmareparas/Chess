import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps Google Play Games Services (Android) / Game Center (iOS).
///
/// All public methods are fire-and-forget — errors are swallowed silently so
/// a GPGS outage or unavailable service never crashes or blocks the game.
///
/// ── HOW TO ACTIVATE ─────────────────────────────────────────────────────────
/// 1. Create achievements in Play Console → Play Games Services → Achievements.
/// 2. Replace every `REPLACE_WITH_*` string below with the IDs you get there.
/// 3. Update `android/app/src/main/res/values/games_ids.xml` with your App ID.
/// 4. Test using a signed APK with a tester account registered in Play Console.
/// ─────────────────────────────────────────────────────────────────────────────
class PlayGamesService {
  PlayGamesService._();
  static final PlayGamesService instance = PlayGamesService._();

  // ── Achievement IDs ─────────────────────────────────────────────────────────
  // Replace each value with the Android achievement ID from Play Console.
  // Format: "CgkI..." (base64-like string)
  static const String firstGame = 'CgkIsqidh_MPEAIQAQ';
  static const String firstWin = 'CgkIsqidh_MPEAIQAg';
  static const String beatLevel5 = 'CgkIsqidh_MPEAIQAw';
  static const String timedWin = 'CgkIsqidh_MPEAIQBA';
  static const String pawnPromotion = 'CgkIsqidh_MPEAIQBQ';
  static const String putInCheck = 'CgkIsqidh_MPEAIQBg';
  static const String play10Games = 'CgkIsqidh_MPEAIQBw';
  static const String play50Games = 'CgkIsqidh_MPEAIQCA';

  static const String _prefKeyGamesPlayed = 'gpgs_games_played';

  bool _signedIn = false;

  // ── Sign-in ─────────────────────────────────────────────────────────────────

  /// Call once after [runApp]. Non-blocking; silently skips if unavailable.
  Future<void> signIn() async {
    try {
      await GamesServices.signIn();
      _signedIn = true;
    } catch (_) {
      // Not signed in — Play Games unavailable or user declined. Continue.
    }
  }

  /// Attempts sign-in without prompting the user if they are not already signed in.
  Future<void> signInSilently() async {
    try {
      if (await GamesServices.isSignedIn) {
        await signIn();
      }
    } catch (_) {
      // Ignore
    }
  }

  /// Opens the native achievements UI screen. Prompts the user to sign in
  /// interactively if not currently signed in.
  Future<void> showAchievements() async {
    try {
      if (!_signedIn) {
        await signIn();
      }
      if (_signedIn) {
        await GamesServices.showAchievements();
      }
    } catch (_) {
      // Swallowed
    }
  }

  // ── Achievement helpers ─────────────────────────────────────────────────────

  /// Unlocks a single achievement by Android ID. Silent no-op if not signed in
  /// or if the ID is still a placeholder.
  void unlock(String androidId) {
    if (!_signedIn || androidId.startsWith('REPLACE_')) return;
    GamesServices.unlock(
      achievement: Achievement(androidID: androidId),
    ).catchError((_) => null);
  }

  // ── Game-event hooks ────────────────────────────────────────────────────────

  /// Call when a new game starts (from [AppModel.newGame]).
  Future<void> onGameStarted() async {
    unlock(firstGame);
    await _incrementGamesPlayed();
  }

  /// Call when the human player wins (from [AppModel.endGame]).
  /// Passes [aiDifficulty] and [timeLimit] to decide extra achievements.
  void onPlayerWon({required int aiDifficulty, required int timeLimit}) {
    unlock(firstWin);
    if (aiDifficulty >= 5) unlock(beatLevel5);
    if (timeLimit > 0) unlock(timedWin);
  }

  /// Call when the human player promotes a pawn (from [GameController.promote]).
  void onPawnPromotion() => unlock(pawnPromotion);

  /// Call when the human player puts the opponent in check.
  void onCheckDelivered() => unlock(putInCheck);

  // ── Game counter ────────────────────────────────────────────────────────────
  // play10Games and play50Games are Incremental achievements in Play Console.
  // We increment by 1 each game using GamesServices.increment() rather than
  // unlock() — Play Games tracks the step count and auto-unlocks at 10 / 50.

  Future<void> _incrementGamesPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_prefKeyGamesPlayed) ?? 0) + 1;
      await prefs.setInt(_prefKeyGamesPlayed, count);

      // Increment the Play Games step counter for both incremental achievements.
      // Play Games auto-unlocks them when steps reach 10 and 50 respectively.
      if (_signedIn) {
        GamesServices.increment(
          achievement: Achievement(androidID: play10Games, steps: 1),
        ).catchError((_) => null);
        GamesServices.increment(
          achievement: Achievement(androidID: play50Games, steps: 1),
        ).catchError((_) => null);
      }
    } catch (_) {/* ignore */}
  }
}
