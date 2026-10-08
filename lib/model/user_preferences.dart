import 'package:shared_preferences/shared_preferences.dart';

import '../logic/timer_service.dart';
import 'app_themes.dart';

const PIECE_THEMES = [
  'Classic',
  'Angular',
  '8-Bit',
  'Letters',
  'Old School',
  'Fairy Tale'
];

const List<String> sortedPieceThemes = [
  '8-Bit',
  'Angular',
  'Classic',
  'Fairy Tale',
  'Letters',
  'Old School',
];

/// Manages user preferences backed by SharedPreferences.
/// Extracted from AppModel to follow single-responsibility principle.
class UserPreferences {
  SharedPreferences? _prefs;

  String pieceTheme = 'Classic';
  String themeName = 'Forest Mint';
  bool showMoveHistory = true;
  bool allowUndoRedo = true;
  bool soundEnabled = true;
  bool showHints = true;
  bool showNotation = false;
  bool enableRotation = true;
  bool enablePieceRotation = true;
  bool hapticEnabled = true;
  bool showCapturedPieces = true;
  bool hasRatedApp = false;
  bool dailyPracticeNotification = true;
  int? reminderHour;
  int timerIncrement = 0;
  String timerMode = TimerModes.increment;

  List<String> get pieceThemes => sortedPieceThemes;

  AppTheme get theme {
    return themeList[themeIndex];
  }

  int get themeIndex {
    var idx = themeList.indexWhere((theme) => theme.name == themeName);
    return idx >= 0 ? idx : 0;
  }

  int get pieceThemeIndex {
    var idx = pieceThemes.indexWhere((theme) => theme == pieceTheme);
    return idx >= 0 ? idx : 0;
  }

  /// Called after any preference changes.
  void Function()? onChanged;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    themeName = _prefs!.getString('themeName') ?? 'Forest Mint';
    pieceTheme = _prefs!.getString('pieceTheme') ?? 'Classic';
    showMoveHistory = _prefs!.getBool('showMoveHistory') ?? true;
    soundEnabled = _prefs!.getBool('soundEnabled') ?? true;
    showHints = _prefs!.getBool('showHints') ?? true;
    showNotation = _prefs!.getBool('showNotation') ?? false;
    enableRotation = _prefs!.getBool('enableRotation') ?? true;
    enablePieceRotation = _prefs!.getBool('enablePieceRotation') ?? true;
    allowUndoRedo = _prefs!.getBool('allowUndoRedo') ?? true;
    hapticEnabled = _prefs!.getBool('hapticEnabled') ?? true;
    showCapturedPieces = _prefs!.getBool('showCapturedPieces') ?? true;
    dailyPracticeNotification =
        _prefs!.getBool('dailyPracticeNotification') ?? true;
    reminderHour = _prefs!.getInt('daily_reminder_hour');
    hasRatedApp = _prefs!.getBool('hasRatedApp') ?? false;
    timerIncrement = _prefs!.getInt('timerIncrement') ?? 0;
    timerMode = _prefs!.getString('timerMode') ?? TimerModes.increment;
    onChanged?.call();
  }

  Future<void> setDailyPracticeNotification(bool enabled) async {
    dailyPracticeNotification = enabled;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool('dailyPracticeNotification', enabled);
    onChanged?.call();
  }

  Future<void> setTheme(int index) async {
    themeName = themeList[index].name ?? "";
    onChanged?.call();
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setString('themeName', themeName);
  }

  Future<void> setPieceTheme(int index) async {
    pieceTheme = pieceThemes[index];
    onChanged?.call();
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setString('pieceTheme', pieceTheme);
  }

  Future<void> setShowMoveHistory(bool show) async {
    showMoveHistory = show;
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setBool('showMoveHistory', show);
    onChanged?.call();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setBool('soundEnabled', enabled);
    onChanged?.call();
  }

  Future<void> setShowHints(bool show) async {
    showHints = show;
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setBool('showHints', show);
    onChanged?.call();
  }

  Future<void> setShowNotation(bool show) async {
    showNotation = show;
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setBool('showNotation', show);
    onChanged?.call();
  }

  Future<void> setEnableRotation(bool enable) async {
    enableRotation = enable;
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setBool('enableRotation', enable);
    onChanged?.call();
  }

  Future<void> setEnablePieceRotation(bool enable) async {
    enablePieceRotation = enable;
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setBool('enablePieceRotation', enable);
    onChanged?.call();
  }

  Future<void> setAllowUndoRedo(bool allow) async {
    allowUndoRedo = allow;
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setBool('allowUndoRedo', allow);
    onChanged?.call();
  }

  Future<void> setHapticEnabled(bool enabled) async {
    hapticEnabled = enabled;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool('hapticEnabled', enabled);
    onChanged?.call();
  }

  Future<void> setShowCapturedPieces(bool show) async {
    showCapturedPieces = show;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool('showCapturedPieces', show);
    onChanged?.call();
  }

  Future<void> setHasRatedApp(bool rated) async {
    hasRatedApp = rated;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool('hasRatedApp', rated);
    onChanged?.call();
  }

  Future<void> setTimerIncrement(int increment) async {
    timerIncrement = increment;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt('timerIncrement', increment);
    onChanged?.call();
  }

  Future<void> setTimerMode(String mode) async {
    timerMode = mode;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('timerMode', mode);
    onChanged?.call();
  }

  Future<void> resetToDefaults() async {
    themeName = 'Forest Mint';
    pieceTheme = 'Classic';
    showMoveHistory = true;
    soundEnabled = true;
    showHints = true;
    showNotation = false;
    enableRotation = true;
    enablePieceRotation = true;
    allowUndoRedo = true;
    hapticEnabled = true;
    showCapturedPieces = true;
    dailyPracticeNotification = true;
    timerIncrement = 0;
    timerMode = TimerModes.increment;

    _prefs ??= await SharedPreferences.getInstance();
    await Future.wait([
      _prefs!.setString('themeName', themeName),
      _prefs!.setString('pieceTheme', pieceTheme),
      _prefs!.setBool('showMoveHistory', showMoveHistory),
      _prefs!.setBool('soundEnabled', soundEnabled),
      _prefs!.setBool('showHints', showHints),
      _prefs!.setBool('showNotation', showNotation),
      _prefs!.setBool('enableRotation', enableRotation),
      _prefs!.setBool('enablePieceRotation', enablePieceRotation),
      _prefs!.setBool('allowUndoRedo', allowUndoRedo),
      _prefs!.setBool('hapticEnabled', hapticEnabled),
      _prefs!.setBool('showCapturedPieces', showCapturedPieces),
      _prefs!.setBool('dailyPracticeNotification', dailyPracticeNotification),
      _prefs!.setInt('timerIncrement', timerIncrement),
      _prefs!.setString('timerMode', timerMode),
    ]);
    onChanged?.call();
  }
}
