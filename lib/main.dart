import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'logic/ad_service.dart';
import 'logic/in_app_update_service.dart';
import 'logic/play_games_service.dart';
import 'logic/shared_functions.dart';
import 'model/app_model.dart';
import 'model/user_preferences.dart';
import 'views/main_menu_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Load preferences first to get the active piece theme
  final prefs = UserPreferences();
  await prefs.load();

  // Load essential assets (active theme and fallback Classic) to speed up startup
  await _loadFlameAssets(prefs.pieceTheme);

  // Initialize AdMob SDK in the background, don't await to block startup
  AdService.instance.initialize();

  final appModel = AppModel(prefs: prefs);

  runApp(
    ChangeNotifierProvider.value(
      value: appModel,
      child: Chess(),
    ),
  );

  // Sign in to Play Games Services silently on startup (non-blocking — silently skips if user is not already logged in at OS level)
  PlayGamesService.instance.signInSilently();

  // Check for Google Play Store updates on Android
  InAppUpdateService.instance.checkForUpdate();
}

Future<void> _loadFlameAssets(String activeTheme) async {
  // Preload and cache logo.png in Flutter's ImageCache to prevent any blinking/delay at startup
  final logoProvider = const AssetImage('assets/images/logo.png');
  final logoStream = logoProvider.resolve(ImageConfiguration.empty);
  final completer = Completer<void>();
  final listener = ImageStreamListener(
    (ImageInfo info, bool synchronousCall) {
      if (!completer.isCompleted) completer.complete();
    },
    onError: (Object exception, StackTrace? stackTrace) {
      if (!completer.isCompleted) completer.complete();
    },
  );
  logoStream.addListener(listener);
  await completer.future;
  logoStream.removeListener(listener);

  List<String> essentialImages = [];

  // 1. Preload active theme and Classic fallback theme images
  for (var theme in {activeTheme, 'Classic'}) {
    for (var color in ['black', 'white']) {
      for (var piece in ['king', 'queen', 'rook', 'bishop', 'knight', 'pawn']) {
        essentialImages
            .add('pieces/${formatPieceTheme(theme)}/${piece}_$color.png');
      }
    }
  }

  await Flame.images.loadAll(essentialImages);
  await FlameAudio.audioCache.loadAll([
    'piece_moved.mp3',
    'win.wav',
    'lose.wav',
    'tie.wav',
  ]);

  // 2. Preload remaining themes asynchronously in the background
  _preloadRemainingThemesInBackground(activeTheme);
}

void _preloadRemainingThemesInBackground(String activeTheme) {
  Future.delayed(const Duration(seconds: 3), () async {
    for (var theme in PIECE_THEMES) {
      if (theme == activeTheme || theme == 'Classic') continue;
      List<String> themeImages = [];
      for (var color in ['black', 'white']) {
        for (var piece in [
          'king',
          'queen',
          'rook',
          'bishop',
          'knight',
          'pawn'
        ]) {
          themeImages
              .add('pieces/${formatPieceTheme(theme)}/${piece}_$color.png');
        }
      }
      try {
        await Flame.images.loadAll(themeImages);
        // Small pause between themes to let the main thread process UI events
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        // Avoid crash if assets fail to load in background
      }
    }
  });
}

class Chess extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Chess',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: 'Inter', fontSize: 16),
          pickerTextStyle: TextStyle(fontFamily: 'Inter'),
        ),
      ),
      home: MainMenuView(),
    );
  }
}
