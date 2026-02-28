import 'dart:async';
import 'dart:math';

import 'package:en_passant/logic/chess_board.dart';
import 'package:en_passant/logic/chess_game.dart';
import 'package:en_passant/logic/game_state_storage.dart';
import 'package:en_passant/logic/move_calculation/move_calculation.dart';
import 'package:en_passant/logic/move_calculation/move_classes/move_meta.dart';
import 'package:en_passant/logic/shared_functions.dart';
import 'package:en_passant/views/components/main_menu_view/game_options/side_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_themes.dart';

const TIMER_ACCURACY_MS = 100;
const PIECE_THEMES = [
  'Classic',
  'Angular',
  '8-Bit',
  'Letters',
  'Video Chess',
  'Lewis Chessmen',
  'Mexico City'
];

class AppModel extends ChangeNotifier {
  int playerCount = 1;
  int aiDifficulty = 3;
  Player selectedSide = Player.player1;
  Player playerSide = Player.player1;
  int timeLimit = 0;
  String pieceTheme = 'Classic';
  String themeName = 'Jargon Jade';
  bool showMoveHistory = true;
  bool allowUndoRedo = true;
  bool soundEnabled = true;
  bool showHints = true;
  bool showNotation = false;
  bool enableRotation = true;

  ChessGame? game;
  Timer? timer;
  bool gameOver = false;
  bool stalemate = false;
  bool promotionRequested = false;
  bool moveListUpdated = false;
  Player turn = Player.player1;
  List<MoveMeta> moveMetaList = [];
  Duration player1TimeLeft = Duration.zero;
  Duration player2TimeLeft = Duration.zero;

  List<String> get pieceThemes {
    var pieceThemes = List<String>.from(PIECE_THEMES);
    pieceThemes.sort();
    return pieceThemes;
  }

  AppTheme get theme {
    return themeList[themeIndex];
  }

  int get themeIndex {
    var themeIndex = 0;
    themeList.asMap().forEach((index, theme) {
      if (theme.name == themeName) {
        themeIndex = index;
      }
    });
    return themeIndex;
  }

  int get pieceThemeIndex {
    var pieceThemeIndex = 0;
    pieceThemes.asMap().forEach((index, theme) {
      if (theme == pieceTheme) {
        pieceThemeIndex = index;
      }
    });
    return pieceThemeIndex;
  }

  Player get aiTurn {
    return oppositePlayer(playerSide);
  }

  bool get isAIsTurn {
    return playingWithAI && (turn == aiTurn);
  }

  bool get playingWithAI {
    return playerCount == 1;
  }

  AppModel() {
    loadSharedPrefs();
  }

  void newGame(BuildContext context, {bool notify = true}) {
    game?.cancelAIMove();
    timer?.cancel();
    GameStateStorage.clearGameState();
    gameOver = false;
    stalemate = false;
    turn = Player.player1;
    moveMetaList = [];
    player1TimeLeft = Duration(minutes: timeLimit);
    player2TimeLeft = Duration(minutes: timeLimit);
    if (selectedSide == Player.random) {
      playerSide =
          Random.secure().nextInt(2) == 0 ? Player.player1 : Player.player2;
    }
    game = ChessGame(this, context);
    _startTimer();
    if (notify) {
      notifyListeners();
    }
  }

  void _startTimer() {
    timer = Timer.periodic(Duration(milliseconds: TIMER_ACCURACY_MS), (timer) {
      turn == Player.player1
          ? decrementPlayer1Timer()
          : decrementPlayer2Timer();
      if ((player1TimeLeft == Duration.zero ||
              player2TimeLeft == Duration.zero) &&
          timeLimit != 0) {
        endGame();
      }
    });
  }

  void exitChessView() {
    game?.cancelAIMove();
    timer?.cancel();
    GameStateStorage.clearGameState();
    notifyListeners();
  }

  void pushMoveMeta(MoveMeta meta) {
    moveMetaList.add(meta);
    moveListUpdated = true;
    notifyListeners();
    saveGameState();
  }

  void popMoveMeta() {
    moveMetaList.removeLast();
    moveListUpdated = true;
    notifyListeners();
    saveGameState();
  }

  void endGame() {
    gameOver = true;
    GameStateStorage.clearGameState();
    notifyListeners();
  }

  void undoEndGame() {
    gameOver = false;
    notifyListeners();
  }

  void changeTurn() {
    turn = oppositePlayer(turn);
    notifyListeners();
  }

  void requestPromotion() {
    promotionRequested = true;
    notifyListeners();
  }

  void setPlayerCount(int? count) {
    if (count != null) {
      playerCount = count;
      notifyListeners();
    }
  }

  void setAIDifficulty(int? difficulty) {
    if (difficulty != null) {
      aiDifficulty = difficulty;
      notifyListeners();
    }
  }

  void setPlayerSide(Player? side) {
    if (side != null) {
      selectedSide = side;
      if (side != Player.random) {
        playerSide = side;
      }
      notifyListeners();
    }
  }

  void setTimeLimit(int? duration) {
    if (duration != null) {
      timeLimit = duration;
      player1TimeLeft = Duration(minutes: timeLimit);
      player2TimeLeft = Duration(minutes: timeLimit);
      notifyListeners();
    }
  }

  void decrementPlayer1Timer() {
    if (player1TimeLeft.inMilliseconds > 0 && !gameOver) {
      player1TimeLeft = Duration(
          milliseconds: player1TimeLeft.inMilliseconds - TIMER_ACCURACY_MS);
      notifyListeners();
    }
  }

  void decrementPlayer2Timer() {
    if (player2TimeLeft.inMilliseconds > 0 && !gameOver) {
      player2TimeLeft = Duration(
          milliseconds: player2TimeLeft.inMilliseconds - TIMER_ACCURACY_MS);
      notifyListeners();
    }
  }

  void setTheme(int index) async {
    themeName = themeList[index].name ?? "";
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('themeName', themeName);
    notifyListeners();
  }

  void setPieceTheme(int index) async {
    pieceTheme = pieceThemes[index];
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('pieceTheme', pieceTheme);
    notifyListeners();
  }

  void setShowMoveHistory(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    showMoveHistory = show;
    prefs.setBool('showMoveHistory', show);
    notifyListeners();
  }

  void setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    soundEnabled = enabled;
    prefs.setBool('soundEnabled', enabled);
    notifyListeners();
  }

  void setShowHints(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    showHints = show;
    prefs.setBool('showHints', show);
    notifyListeners();
  }

  void setShowNotation(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    showNotation = show;
    prefs.setBool('showNotation', show);
    notifyListeners();
  }

  void setEnableRotation(bool enableRotation) async {
    final prefs = await SharedPreferences.getInstance();
    this.enableRotation = enableRotation;
    prefs.setBool('enableRotation', enableRotation);
    notifyListeners();
  }

  void setAllowUndoRedo(bool allow) async {
    final prefs = await SharedPreferences.getInstance();
    this.allowUndoRedo = allow;
    prefs.setBool('allowUndoRedo', allow);
    notifyListeners();
  }

  void loadSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    themeName = prefs.getString('themeName') ?? 'Jargon Jade';
    pieceTheme = prefs.getString('pieceTheme') ?? 'Classic';
    showMoveHistory = prefs.getBool('showMoveHistory') ?? true;
    soundEnabled = prefs.getBool('soundEnabled') ?? true;
    showHints = prefs.getBool('showHints') ?? true;
    showNotation = prefs.getBool('showNotation') ?? false;
    enableRotation = prefs.getBool('enableRotation') ?? true;
    allowUndoRedo = prefs.getBool('allowUndoRedo') ?? true;
    notifyListeners();
  }

  void update() {
    notifyListeners();
  }

  void saveGameState() {
    GameStateStorage.saveGameState(this);
  }

  Future<void> restoreGameState(BuildContext context) async {
    final state = await GameStateStorage.loadGameState();
    if (state == null) return;

    game?.cancelAIMove();
    timer?.cancel();

    playerCount = state['playerCount'] as int;
    aiDifficulty = state['aiDifficulty'] as int;
    playerSide = Player.values[state['playerSide'] as int];
    selectedSide = Player.values[state['selectedSide'] as int];
    timeLimit = state['timeLimit'] as int;
    pieceTheme = state['pieceTheme'] as String;
    gameOver = state['gameOver'] as bool;
    stalemate = state['stalemate'] as bool;
    turn = Player.player1;
    moveMetaList = [];

    // Create a fresh game and replay all moves
    game = ChessGame(this, context);
    final moves = GameStateStorage.parseMoves(state);
    for (var move in moves) {
      var meta = push(move, game!.board,
          getMeta: true, promotionType: move.promotionType);
      moveMetaList.add(meta);
      turn = oppositePlayer(turn);
    }

    // Restore timer durations
    player1TimeLeft = Duration(milliseconds: state['player1TimeLeftMs'] as int);
    player2TimeLeft = Duration(milliseconds: state['player2TimeLeftMs'] as int);

    // Restore game over / stalemate state
    gameOver = state['gameOver'] as bool;
    stalemate = state['stalemate'] as bool;

    // Update visual state from last move
    if (moveMetaList.isNotEmpty) {
      game!.latestMove = moveMetaList.last.move;
      var oppositeTurn = oppositePlayer(turn);
      if (kingInCheck(oppositeTurn, game!.board)) {
        game!.checkHintTile = kingForPlayer(oppositeTurn, game!.board)?.tile;
      }
    }

    _startTimer();

    notifyListeners();

    // Trigger AI move if it's AI's turn
    if (isAIsTurn && !gameOver) {
      game!.triggerAIMove();
    }
  }
}
