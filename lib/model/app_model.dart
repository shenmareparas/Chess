import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../logic/ad_service.dart';
import '../logic/audio_service.dart';
import '../logic/chess_notation_service.dart';
import '../logic/chess_piece.dart';
import '../logic/game_controller.dart';
import '../logic/game_state_storage.dart';
import '../logic/haptic_service.dart';
import '../logic/move_calculation/move_classes/move_meta.dart';
import '../logic/move_calculation/move_classes/move_stack_object.dart';
import '../logic/notification_service.dart';
import '../logic/play_games_service.dart';
import '../logic/rating_service.dart';
import '../logic/shared_functions.dart';
import '../logic/stockfish_service.dart';
import '../logic/timer_service.dart';
import 'app_themes.dart';
import 'game_state.dart';
import 'player.dart';
import 'user_preferences.dart';

class AppModel extends ChangeNotifier {
  // ── Game Settings ──
  int playerCount = 1;
  int aiDifficulty = 1;
  Player selectedSide = Player.player1;
  Player playerSide = Player.player1;

  /// The side Player 1 chooses to start on in a 2-player game.
  Player selectedSideP1 = Player.player1;

  // ── Services ──
  final UserPreferences prefs;
  final AudioService audio = AudioService();
  final TimerService timerService = TimerService();
  final HapticService haptic = HapticService();

  // ── Delegated Accessors (backward compatibility) ──
  int get timeLimit => timerService.timeLimit;
  String get pieceTheme => prefs.pieceTheme;
  String get themeName => prefs.themeName;
  bool get showMoveHistory => prefs.showMoveHistory;
  bool get allowUndoRedo => prefs.allowUndoRedo;
  bool get soundEnabled => prefs.soundEnabled;
  bool get showHints => prefs.showHints;
  bool get showNotation => prefs.showNotation;
  bool get enableRotation => prefs.enableRotation;
  bool get enablePieceRotation => prefs.enablePieceRotation;
  bool get hapticEnabled => prefs.hapticEnabled;
  bool get showCapturedPieces => prefs.showCapturedPieces;
  bool get isAdFree => prefs.isAdFree;
  bool get dailyPracticeNotification => prefs.dailyPracticeNotification;
  int get timerIncrement => prefs.timerIncrement;
  String get timerMode => prefs.timerMode;
  AppTheme get theme => prefs.theme;
  int get themeIndex => prefs.themeIndex;
  int get pieceThemeIndex => prefs.pieceThemeIndex;
  List<String> get pieceThemes => prefs.pieceThemes;

  bool get hasRatedApp => prefs.hasRatedApp;

  ValueNotifier<Duration> get player1TimeLeft => timerService.player1TimeLeft;
  set player1TimeLeft(ValueNotifier<Duration> val) =>
      timerService.player1TimeLeft.value = val.value;
  ValueNotifier<Duration> get player2TimeLeft => timerService.player2TimeLeft;
  set player2TimeLeft(ValueNotifier<Duration> val) =>
      timerService.player2TimeLeft.value = val.value;

  // ── Game State (Model) ──
  /// Pure game-outcome data, separated from ViewModel concerns.
  /// Access via the proxy getters below; do not reach into [_gameState] directly
  /// from outside this class.
  final GameState _gameState = GameState();

  // Proxy getters/setters — all external code reads appModel.gameOver etc.
  // as before; we just delegate to the model layer now.
  bool get gameOver => _gameState.gameOver;
  set gameOver(bool v) => _gameState.gameOver = v;
  bool get stalemate => _gameState.stalemate;
  set stalemate(bool v) => _gameState.stalemate = v;
  FideDrawReason? get drawReason => _gameState.drawReason;
  set drawReason(FideDrawReason? v) => _gameState.drawReason = v;
  bool get userWon => _gameState.userWon;
  set userWon(bool v) => _gameState.userWon = v;
  Player get turn => _gameState.turn;
  set turn(Player v) => _gameState.turn = v;
  List<MoveMeta> get moveMetaList => _gameState.moveMetaList;
  set moveMetaList(List<MoveMeta> v) => _gameState.moveMetaList = v;

  // ── ViewModel-layer game state ──
  GameController? gameController;
  bool promotionRequested = false;
  bool moveListUpdated = false;
  int? historyViewIndex;
  final List<MoveStackObject> historyRedoStack = [];
  Timer? _historyAnimationTimer;

  /// Set to true once the essential piece-image assets have finished decoding
  /// after runApp(). Until then, navigation to ChessView is disabled.
  bool imagesReady = false;

  /// Set to true when exiting the match view to prevent lifecycle events
  /// or debounce timers from saving state after an explicit exit.
  bool isExiting = false;

  /// Whether the match is in fullscreen mode (hiding system bars and exit/restart controls).
  bool _isFullscreen = false;
  bool get isFullscreen => _isFullscreen;

  /// In fullscreen mode, whether captured pieces are positioned on the left/right
  /// sides instead of top/bottom to maximize vertical board size.
  bool _sideCapturedPieces = false;
  bool get sideCapturedPieces => _sideCapturedPieces;

  /// In fullscreen mode with side captured pieces, whether the left and right sides are flipped.
  bool _flipSideCapturedPieces = false;
  bool get flipSideCapturedPieces => _flipSideCapturedPieces;

  void toggleFullscreen() {
    _isFullscreen = !_isFullscreen;
    if (!_isFullscreen) {
      _sideCapturedPieces = false;
      _flipSideCapturedPieces = false;
    }
    notifyListeners();
  }

  void setFullscreen(bool value) {
    if (_isFullscreen != value) {
      _isFullscreen = value;
      if (!_isFullscreen) {
        _sideCapturedPieces = false;
        _flipSideCapturedPieces = false;
      }
      notifyListeners();
    }
  }

  void toggleSideCapturedPieces() {
    _sideCapturedPieces = !_sideCapturedPieces;
    notifyListeners();
  }

  void setSideCapturedPieces(bool value) {
    if (_sideCapturedPieces != value) {
      _sideCapturedPieces = value;
      notifyListeners();
    }
  }

  void toggleFlipSideCapturedPieces() {
    _flipSideCapturedPieces = !_flipSideCapturedPieces;
    notifyListeners();
  }

  void setFlipSideCapturedPieces(bool value) {
    if (_flipSideCapturedPieces != value) {
      _flipSideCapturedPieces = value;
      notifyListeners();
    }
  }

  // ── Computed Properties ──
  Player get aiTurn => oppositePlayer(playerSide);
  bool get isAIsTurn =>
      playingWithAI && (turn == aiTurn) && (historyViewIndex == null);
  bool get playingWithAI => playerCount == 1;

  /// Pieces captured from [player]'s side (i.e. pieces that player lost).
  /// Returns an empty list if no game or board is active.
  List<ChessPieceType> capturedPiecesFor(Player player) =>
      gameController?.board.capturedPiecesFor(player) ?? const [];

  // ── Save Debounce ──
  Timer? _saveDebounceTimer;

  // ── Undo Bank ──
  /// Number of free undos remaining for the current game.
  /// Starts at 1 for each new game. Players can earn 1 more by watching an ad.
  int _availableUndos = 1;
  int get availableUndos => isAdFree ? 999 : _availableUndos;

  void resetUndos() {
    _availableUndos = 1;
    notifyListeners();
  }

  void decrementUndo() {
    if (isAdFree) return;

    if (_availableUndos > 0) {
      _availableUndos--;
      // Preload rewarded ad lazily as soon as the user exhausts their free undo,
      // so it is prepared ahead of time if they request an extra undo later.
      if (_availableUndos == 0) {
        AdService.instance.preloadRewardedAd();
      }
      notifyListeners();
    }
  }

  void grantUndoFromAd() {
    _availableUndos++;
    notifyListeners();
  }

  // ── Undo / Redo (ViewModel commands & queries) ──

  bool get canUndo {
    final controller = gameController;
    if (historyViewIndex != null || controller == null) return false;
    final moveStack = controller.board.moveStack;
    if (moveStack.isEmpty) return false;

    if (playingWithAI) {
      final lastMovePlayer = moveStack.last.movedPiece?.player;
      if (lastMovePlayer == playerSide) {
        return moveStack.isNotEmpty;
      }
      return moveStack.length >= 2;
    }
    return true;
  }

  bool get canRedo {
    final controller = gameController;
    if (historyViewIndex != null || controller == null) return false;
    return controller.board.redoStack.isNotEmpty;
  }

  /// Performs the correct undo (1 move in 2P, 2 moves in AI mode).
  void undo() {
    final controller = gameController;
    if (controller == null) return;
    controller.cancelAIMove();
    if (playingWithAI) {
      final moveStack = controller.board.moveStack;
      if (moveStack.isEmpty) return;

      final lastMovePlayer = moveStack.last.movedPiece?.player;
      if (lastMovePlayer == playerSide) {
        controller.undoMove();
      } else if (moveStack.length >= 2) {
        controller.undoTwoMoves();
      } else {
        controller.undoMove();
      }
    } else {
      controller.undoMove();
    }
  }

  /// Redoes 1 move in 2P, 2 moves in AI mode (when two redos are queued).
  void redo() {
    final controller = gameController;
    if (controller == null) return;
    final redoStack = controller.board.redoStack;
    if (redoStack.isEmpty) return;
    if (playingWithAI && redoStack.length >= 2) {
      controller.redoTwoMoves();
    } else {
      controller.redoMove();
    }
  }

  // Used to prevent AnimatedRotation from sweeping across the screen when first loading the board.
  bool animateBoardRotation = false;
  bool? _gameOverInvertedState;

  bool get isBoardInverted {
    if (_gameOverInvertedState != null && gameOver) {
      return _gameOverInvertedState!;
    }
    if (playingWithAI || historyViewIndex != null) {
      return playerSide == Player.player2;
    } else {
      return enableRotation && turn == Player.player2;
    }
  }

  /// Whether pieces should be visually rotated 180 degrees (in 2P mode on Player 2's turn).
  bool get isPieceRotated {
    return enablePieceRotation &&
        !enableRotation &&
        !playingWithAI &&
        historyViewIndex == null &&
        playerCount == 2 &&
        turn == Player.player2;
  }

  // ── Saved Game Availability (Reactive) ──
  bool _hasSavedGame = false;
  bool get hasSavedGame => _hasSavedGame;

  Future<void> refreshHasSavedGame() async {
    final has = await GameStateStorage.hasSavedGame();
    if (_hasSavedGame != has) {
      _hasSavedGame = has;
      notifyListeners();
    }
  }

  AppModel({UserPreferences? prefs}) : prefs = prefs ?? UserPreferences() {
    // Wire up service callbacks
    this.prefs.onChanged = () => notifyListeners();
    timerService.onExpired = () => endGame();
    audio.enabled = this.prefs.soundEnabled;
    audio.initialize();
    haptic.enabled = this.prefs.hapticEnabled;

    // Check saved game availability asynchronously on start
    refreshHasSavedGame();

    // Note: prefs.load() is intentionally NOT called here. The caller
    // (main.dart) awaits prefs.load() before constructing AppModel so that
    // all preferences are available from the very first frame.
  }

  // ── Game Lifecycle ──

  void newGame({bool notify = true}) {
    isExiting = false;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
    gameController?.cancelAIMove();
    timerService.stop();
    GameStateStorage.clearGameState();
    refreshHasSavedGame();
    _gameOverInvertedState = null;
    _gameState.reset(); // reset all pure-model game state in one call
    promotionRequested = false;
    moveListUpdated = false;
    historyViewIndex = null;
    historyRedoStack.clear();
    _historyAnimationTimer?.cancel();
    timerService.configure(timeLimit,
        incrementSeconds: timerIncrement, mode: timerMode);
    audio.enabled = prefs.soundEnabled;
    // Reset undo bank for the new game.
    _availableUndos = 1;
    if (selectedSide == Player.random) {
      playerSide = math.Random.secure().nextInt(2) == 0
          ? Player.player1
          : Player.player2;
    } else {
      playerSide = selectedSide;
    }

    // In a 2-player game, let Player 1 start on their chosen side.
    if (!playingWithAI) {
      if (selectedSideP1 == Player.random) {
        playerSide = math.Random.secure().nextInt(2) == 0
            ? Player.player1
            : Player.player2;
      } else {
        playerSide = selectedSideP1;
      }
    }
    // Dispose the previous controller's background isolate before replacing it.
    gameController?.dispose();
    gameController = GameController(this);
    timerService.start(() => turn, () => gameOver);

    // Trigger AI move if it's AI's turn natively for standard games
    if (isAIsTurn && !gameOver) {
      gameController!.triggerAIMove();
    }

    // Play Games: track game start and unlock milestone achievements
    PlayGamesService.instance.onGameStarted();

    // Record user play time to adapt daily practice reminder timing
    NotificationService.instance.recordGamePlayTime();

    // Disable animation on load, then enable it after the board is rendered.
    animateBoardRotation = false;
    Future.delayed(Duration(milliseconds: 50), () {
      animateBoardRotation = true;
      notifyListeners();
    });

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> exitChessView() async {
    isExiting = true;
    _isFullscreen = false;
    _sideCapturedPieces = false;
    _flipSideCapturedPieces = false;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
    gameController?.cancelAIMove();
    timerService.stop();
    await GameStateStorage.clearGameState();
    await refreshHasSavedGame();
    historyViewIndex = null;
    notifyListeners();
  }

  Future<void> saveAndExitChessView() async {
    if (historyViewIndex != null) {
      setHistoryViewIndex(null, snap: true, playAudio: false);
    }
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
    if (!gameOver) {
      await GameStateStorage.saveGameState(this);
    }
    await refreshHasSavedGame();
    isExiting = true;
    _isFullscreen = false;
    _sideCapturedPieces = false;
    _flipSideCapturedPieces = false;
    gameController?.cancelAIMove();
    timerService.stop();
    notifyListeners();
  }

  /// Handles the full exit flow: rating prompt (if applicable) then interstitial ad.
  Future<void> handleGameExit(BuildContext context) async {
    Future<void> performExit() async {
      await exitChessView();
      if (context.mounted) {
        AdService.instance.showExitInterstitialAd(
          onAdDismissed: () {
            if (context.mounted) Navigator.of(context).pop();
          },
        );
      }
    }

    if (userWon && !hasRatedApp) {
      RatingService.instance.showRatingPrompt(
        context,
        prefs: prefs,
        onComplete: performExit,
      );
    } else {
      await performExit();
    }
  }

  // ── Move State Management ──

  void pushMoveMeta(MoveMeta meta, {bool silent = false}) {
    moveMetaList.add(meta);
    moveListUpdated = true;
    if (!silent) notifyListeners();
    saveGameState();
  }

  void popMoveMeta({bool silent = false}) {
    moveMetaList.removeLast();
    moveListUpdated = true;
    if (!silent) notifyListeners();
    saveGameState();
  }

  void setHistoryViewIndex(int? index,
      {int? visualIndex,
      bool snap = true,
      bool playAudio = false,
      bool showLatestMoveHighlight = true}) {
    if (gameController == null) return;
    _historyAnimationTimer?.cancel();

    // Clear any selection/hints on history navigation.
    gameController!.selectedPiece = null;
    gameController!.validMoves = const [];
    gameController!.warningTile = null;

    // If returning to current live state (latest move or null)
    if (index == null || index == moveMetaList.length - 1) {
      while (historyRedoStack.isNotEmpty) {
        gameController!.board.pushMSO(historyRedoStack.removeLast());
      }
      historyViewIndex = null;
      moveListUpdated = true;
      if (moveMetaList.isNotEmpty) {
        gameController!.latestMove = moveMetaList.last.move;
        if (gameController!.board.kingInCheck(turn)) {
          gameController!.checkHintTile =
              gameController!.board.kingForPlayer(turn)?.tile;
        } else {
          gameController!.checkHintTile = null;
        }
      } else {
        gameController!.latestMove = null;
        gameController!.checkHintTile = null;
      }
      if (!gameOver) {
        timerService.resume();
        if (isAIsTurn) {
          gameController!.triggerAIMove();
        }
      }
      if (playAudio) {
        audio.playMovedSound();
      }
      gameController!.snapSprites(snap: snap);
      notifyListeners();
      return;
    }

    // Do not pause game during review
    gameController?.cancelAIMove();

    int targetLength = index + 1;
    if (gameController!.board.moveStack.length > targetLength) {
      while (gameController!.board.moveStack.length > targetLength) {
        historyRedoStack.add(gameController!.board.pop());
      }
    } else if (gameController!.board.moveStack.length < targetLength) {
      while (gameController!.board.moveStack.length < targetLength &&
          historyRedoStack.isNotEmpty) {
        gameController!.board.pushMSO(historyRedoStack.removeLast());
      }
    }

    historyViewIndex = visualIndex ?? index;
    if (index >= 0 && index < moveMetaList.length) {
      if (showLatestMoveHighlight) {
        gameController!.latestMove = moveMetaList[index].move;
      } else {
        gameController!.latestMove = null;
      }
      final mover = moveMetaList[index].player;
      if (mover != null) {
        final checkedPlayer = oppositePlayer(mover);
        if (gameController!.board.kingInCheck(checkedPlayer)) {
          gameController!.checkHintTile =
              gameController!.board.kingForPlayer(checkedPlayer)?.tile;
        } else {
          gameController!.checkHintTile = null;
        }
      } else {
        gameController!.checkHintTile = null;
      }
    } else {
      gameController!.latestMove = null;
      gameController!.checkHintTile = null;
    }
    if (playAudio) {
      audio.playMovedSound();
    }
    gameController!.snapSprites(snap: snap);
    notifyListeners();
  }

  void selectHistoryTurn(int turnIndex) {
    _historyAnimationTimer?.cancel();

    final int whiteMoveIndex = turnIndex * 2;
    final int? blackMoveIndex =
        (turnIndex * 2 + 1 < moveMetaList.length) ? (turnIndex * 2 + 1) : null;

    // 1. Instantly snap to the position before White's move (index - 1, or -1 for the very start)
    // Pass visualIndex: whiteMoveIndex so that the UI immediately highlights the selected turn tile.
    // Set showLatestMoveHighlight: false so the board does not show the previous turn's highlight squares.
    final int beforeWhiteIndex = whiteMoveIndex > 0 ? (whiteMoveIndex - 1) : -1;
    setHistoryViewIndex(beforeWhiteIndex,
        visualIndex: whiteMoveIndex,
        snap: true,
        playAudio: false,
        showLatestMoveHighlight: false);

    // 2. Schedule White's move to play with animation (snap = false) after a brief frame delay
    _historyAnimationTimer = Timer(const Duration(milliseconds: 250), () {
      setHistoryViewIndex(whiteMoveIndex,
          visualIndex: whiteMoveIndex, snap: false, playAudio: true);

      // 3. Schedule Black's move to play after the White move finishes sliding
      if (blackMoveIndex != null) {
        _historyAnimationTimer = Timer(const Duration(milliseconds: 600), () {
          setHistoryViewIndex(blackMoveIndex,
              visualIndex: blackMoveIndex, snap: false, playAudio: true);
        });
      }
    });
  }

  // ── Move History Navigation (ViewModel Commands) ──

  /// Steps one half-move backward in the history viewer.
  void stepHistoryBackward() {
    final idx = historyViewIndex;
    if (idx == null || idx <= 0) return;
    haptic.light();
    final int currentTurnIndex = (idx / 2).floor();
    if (idx == 1) {
      selectHistoryTurn(0);
    } else if (currentTurnIndex > 0) {
      selectHistoryTurn(currentTurnIndex - 1);
    } else {
      setHistoryViewIndex(0, snap: true, playAudio: false);
    }
  }

  /// Steps one half-move forward in the history viewer, or exits history mode.
  void stepHistoryForward() {
    final idx = historyViewIndex;
    if (idx == null) return;
    haptic.light();
    final int currentTurnIndex = idx < 0 ? -1 : (idx / 2).floor();
    final int totalTurns = (moveMetaList.length / 2).ceil();
    if (currentTurnIndex < totalTurns - 1) {
      selectHistoryTurn(currentTurnIndex + 1);
    } else {
      setHistoryViewIndex(null);
    }
  }

  void endGame({
    bool silent = false,
    Player? winner,
    bool stalemate = false,
    FideDrawReason? drawReason,
  }) {
    if (gameOver) return;
    _gameOverInvertedState = isBoardInverted;
    gameOver = true;
    if (stalemate || drawReason != null) {
      this.stalemate = true;
      this.drawReason = drawReason ?? FideDrawReason.stalemate;
    }

    final actualWinner = winner ?? turn;

    userWon = audio.didUserWin(
      playingWithAI: playingWithAI,
      playerSide: playerSide,
      turn: actualWinner,
      player1TimeLeft: player1TimeLeft.value,
      player2TimeLeft: player2TimeLeft.value,
    );

    audio.playGameEndSound(
      stalemate: this.stalemate,
      playingWithAI: playingWithAI,
      playerSide: playerSide,
      turn: actualWinner,
      player1TimeLeft: player1TimeLeft.value,
      player2TimeLeft: player2TimeLeft.value,
    );

    // Play Games: unlock win achievements
    if (userWon && playingWithAI) {
      PlayGamesService.instance.onPlayerWon(
        aiDifficulty: aiDifficulty,
        timeLimit: timeLimit,
      );
    }

    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
    GameStateStorage.clearGameState();
    if (!silent) notifyListeners();
  }

  void undoEndGame({bool silent = false}) {
    gameOver = false;
    stalemate = false;
    drawReason = null;
    userWon = false;
    _gameOverInvertedState = null;
    if (timeLimit > 0) {
      timerService.start(() => turn, () => gameOver);
    }
    if (!silent) notifyListeners();
  }

  /// Exports the complete game as a standard PGN string with tournament headers.
  String exportPgn() {
    final controller = gameController;
    if (controller == null) return '';

    String whiteName;
    String blackName;
    if (playingWithAI) {
      final aiLabel =
          'Stockfish L$aiDifficulty (${AppModel.getDifficultyElo(aiDifficulty)} ELO)';
      if (playerSide == Player.player1) {
        whiteName = 'Player 1';
        blackName = aiLabel;
      } else {
        whiteName = aiLabel;
        blackName = 'Player 1';
      }
    } else {
      whiteName = 'Player 1';
      blackName = 'Player 2';
    }

    String? result;
    if (gameOver) {
      if (stalemate) {
        result = '1/2-1/2';
      } else if (turn == Player.player2) {
        result = '1-0';
      } else {
        result = '0-1';
      }
    }

    return ChessNotationService.instance.generatePgn(
      moveStack: controller.board.moveStack,
      whiteName: whiteName,
      blackName: blackName,
      result: result,
    );
  }

  /// Exports the current board position as a standard FEN string.
  String exportFen() {
    final controller = gameController;
    if (controller == null) return '';
    return ChessNotationService.instance.exportFen(controller.board.moveStack);
  }

  void changeTurn({bool silent = false}) {
    turn = oppositePlayer(turn);
    if (!silent) notifyListeners();
  }

  void requestPromotion() {
    promotionRequested = true;
    notifyListeners();
  }

  /// Delegates pawn promotion to the active GameController.
  void promote(ChessPieceType type) => gameController?.promote(type);

  // ── Game Options ──

  void setPlayerCount(int? count) {
    if (count != null) {
      haptic.light();
      playerCount = count;
      notifyListeners();
    }
  }

  void setAIDifficulty(int? difficulty) {
    if (difficulty != null) {
      haptic.light();
      aiDifficulty = difficulty;
      notifyListeners();
    }
  }

  static int getDifficultyElo(int level) {
    switch (level) {
      case 1:
        return 400;
      case 2:
        return 800;
      case 3:
        return 1200;
      case 4:
        return 1600;
      case 5:
        return 2000;
      default:
        return 1200;
    }
  }

  void setPlayerSide(Player? side) {
    if (side != null) {
      haptic.light();
      selectedSide = side;
      if (side != Player.random) {
        playerSide = side;
      }
      notifyListeners();
    }
  }

  void setPlayerSideP1(Player? side) {
    if (side != null) {
      haptic.light();
      selectedSideP1 = side;
      notifyListeners();
    }
  }

  void setTimeLimit(int? duration) {
    if (duration != null) {
      haptic.light();
      timerService.configure(duration);
      notifyListeners();
    }
  }

  // ── Preference Delegation ──

  void setTheme(int index) {
    haptic.light();
    prefs.setTheme(index);
  }

  void setPieceTheme(int index) {
    haptic.light();
    prefs.setPieceTheme(index);
  }

  void setShowMoveHistory(bool show) {
    haptic.light();
    prefs.setShowMoveHistory(show);
  }

  void setSoundEnabled(bool enabled) {
    haptic.light();
    prefs.setSoundEnabled(enabled);
    audio.enabled = enabled;
  }

  void setShowHints(bool show) {
    haptic.light();
    prefs.setShowHints(show);
  }

  void setShowNotation(bool show) {
    haptic.light();
    prefs.setShowNotation(show);
  }

  void setEnableRotation(bool enable) {
    haptic.light();
    prefs.setEnableRotation(enable);
  }

  void setEnablePieceRotation(bool enable) {
    haptic.light();
    prefs.setEnablePieceRotation(enable);
  }

  void setShowCapturedPieces(bool show) {
    haptic.light();
    prefs.setShowCapturedPieces(show);
  }

  void setDailyPracticeNotification(bool enabled) {
    haptic.light();
    prefs.setDailyPracticeNotification(enabled);
    if (enabled) {
      NotificationService.instance.scheduleAdaptiveDailyReminder();
    } else {
      NotificationService.instance.cancelDailyReminder();
    }
    notifyListeners();
  }

  void setAllowUndoRedo(bool allow) {
    haptic.light();
    prefs.setAllowUndoRedo(allow);
  }

  void setHapticEnabled(bool enabled) {
    prefs.setHapticEnabled(enabled);
    haptic.enabled = enabled;
    haptic.light();
  }

  void setTimerIncrement(int increment) {
    haptic.light();
    prefs.setTimerIncrement(increment);
  }

  void setTimerMode(String mode) {
    haptic.light();
    prefs.setTimerMode(mode);
  }

  void showAchievements() => PlayGamesService.instance.showAchievements();

  Future<void> resetSettingsToDefaults() async {
    await prefs.resetToDefaults();
    audio.enabled = prefs.soundEnabled;
    haptic.enabled = prefs.hapticEnabled;
    NotificationService.instance.scheduleAdaptiveDailyReminder();
    notifyListeners();
  }

  // ── Utilities ──

  void update() {
    notifyListeners();
  }

  /// Schedules a save after a short debounce window (400 ms).
  /// Rapid undo/redo or move bursts collapse into a single write,
  /// preventing SharedPreferences I/O on every single event.
  void saveGameState() {
    if (gameOver || isExiting) return;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(
      const Duration(milliseconds: 400),
      () => GameStateStorage.saveGameState(this),
    );
  }

  /// Immediately flushes the game state to disk, bypassing the debounce.
  /// Use this in lifecycle events (app pause, explicit exit) to ensure
  /// no data is lost.
  void saveGameStateImmediate() {
    if (gameOver || isExiting) return;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
    GameStateStorage.saveGameState(this);
  }

  Future<void> restoreGameState() async {
    final state = await GameStateStorage.loadGameState();
    if (state == null) return;

    isExiting = false;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
    gameController?.cancelAIMove();
    timerService.stop();

    playerCount = state['playerCount'] as int;
    aiDifficulty = state['aiDifficulty'] as int;
    playerSide = Player.values[state['playerSide'] as int];
    selectedSide = Player.values[state['selectedSide'] as int];
    selectedSideP1 = Player
        .values[(state['selectedSideP1'] as int?) ?? Player.player1.index];
    // timerService will be fully configured below once increment + mode are
    // read from state. gameOver/stalemate are restored after move replay.
    turn = Player.player1;
    moveMetaList = [];
    historyViewIndex = null;
    historyRedoStack.clear();
    _historyAnimationTimer?.cancel();

    // Create a fresh game and replay all moves
    gameController?.dispose();
    gameController = GameController(this);
    final moves = GameStateStorage.parseMoves(state);
    for (var move in moves) {
      var meta = gameController!.board
          .push(move, getMeta: true, promotionType: move.promotionType);
      moveMetaList.add(meta);
      turn = oppositePlayer(turn);
    }
    gameController!.snapSprites();

    // Restore timer durations
    player1TimeLeft.value =
        Duration(milliseconds: state['player1TimeLeftMs'] as int);
    player2TimeLeft.value =
        Duration(milliseconds: state['player2TimeLeftMs'] as int);

    // Restore timer increment and mode
    // Assign fields directly — using the setters would trigger a SharedPrefs
    // write and an extra notifyListeners() call for each, both of which are
    // undesirable mid-restore. The values were just read from SharedPrefs.
    final savedIncrement = (state['timerIncrement'] as int?) ?? 0;
    prefs.timerIncrement = savedIncrement;
    final savedMode = (state['timerMode'] as String?) ?? 'increment';
    prefs.timerMode = savedMode;
    timerService.configure(state['timeLimit'] as int,
        incrementSeconds: savedIncrement, mode: savedMode);

    // Restore game over / stalemate state
    gameOver = state['gameOver'] as bool;
    stalemate = state['stalemate'] as bool;

    // Restore undo bank (falls back to 1 for saves predating this feature).
    _availableUndos = (state['availableUndos'] as int?) ?? 1;

    // Update visual state from last move
    if (moveMetaList.isNotEmpty) {
      gameController!.latestMove = moveMetaList.last.move;
      if (gameController!.board.kingInCheck(turn)) {
        gameController!.checkHintTile =
            gameController!.board.kingForPlayer(turn)?.tile;
      }
    }

    timerService.start(() => turn, () => gameOver);

    moveListUpdated = true;
    refreshHasSavedGame();
    notifyListeners();

    // Trigger AI move if it's AI's turn
    if (isAIsTurn && !gameOver) {
      gameController!.triggerAIMove();
    }

    animateBoardRotation = false;
    Future.delayed(Duration(milliseconds: 50), () {
      animateBoardRotation = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    audio.dispose();
    gameController?.dispose();
    StockfishService.instance.dispose();
    super.dispose();
  }
}
