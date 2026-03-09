import 'package:en_passant/model/app_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

const PIECE_THEMES = [
  'Classic',
  'Angular',
  '8-Bit',
  'Letters',
  'Video Chess',
  'Lewis Chessmen',
  'Mexico City'
];

final List<String> sortedPieceThemes = () {
  var list = List<String>.from(PIECE_THEMES);
  list.sort();
  return list;
}();

/// Manages user preferences backed by SharedPreferences.
/// Extracted from AppModel to follow single-responsibility principle.
class UserPreferences {
  SharedPreferences? _prefs;

  String pieceTheme = 'Classic';
  String themeName = 'Jargon Jade';
  bool showMoveHistory = true;
  bool allowUndoRedo = true;
  bool soundEnabled = true;
  bool showHints = true;
  bool showNotation = false;
  bool enableRotation = true;

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
    themeName = _prefs!.getString('themeName') ?? 'Jargon Jade';
    pieceTheme = _prefs!.getString('pieceTheme') ?? 'Classic';
    showMoveHistory = _prefs!.getBool('showMoveHistory') ?? true;
    soundEnabled = _prefs!.getBool('soundEnabled') ?? true;
    showHints = _prefs!.getBool('showHints') ?? true;
    showNotation = _prefs!.getBool('showNotation') ?? false;
    enableRotation = _prefs!.getBool('enableRotation') ?? true;
    allowUndoRedo = _prefs!.getBool('allowUndoRedo') ?? true;
    onChanged?.call();
  }

  Future<void> setTheme(int index) async {
    themeName = themeList[index].name ?? "";
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setString('themeName', themeName);
    onChanged?.call();
  }

  Future<void> setPieceTheme(int index) async {
    pieceTheme = pieceThemes[index];
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setString('pieceTheme', pieceTheme);
    onChanged?.call();
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

  Future<void> setAllowUndoRedo(bool allow) async {
    allowUndoRedo = allow;
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setBool('allowUndoRedo', allow);
    onChanged?.call();
  }

  Future<void> resetToDefaults() async {
    themeName = 'Jargon Jade';
    pieceTheme = 'Classic';
    showMoveHistory = true;
    soundEnabled = true;
    showHints = true;
    showNotation = false;
    enableRotation = true;
    allowUndoRedo = true;

    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('themeName', themeName);
    await _prefs!.setString('pieceTheme', pieceTheme);
    await _prefs!.setBool('showMoveHistory', showMoveHistory);
    await _prefs!.setBool('soundEnabled', soundEnabled);
    await _prefs!.setBool('showHints', showHints);
    await _prefs!.setBool('showNotation', showNotation);
    await _prefs!.setBool('enableRotation', enableRotation);
    await _prefs!.setBool('allowUndoRedo', allowUndoRedo);
    onChanged?.call();
  }
}
