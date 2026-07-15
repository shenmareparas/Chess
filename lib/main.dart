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

  // Load preferences first — lightweight SharedPreferences read only.
  final prefs = UserPreferences();
  await prefs.load();

  // Initialize AdMob SDK in the background, don't await to block startup
  AdService.instance.initialize();

  final appModel = AppModel(prefs: prefs);

  // Launch the UI immediately — the logo appears on the very first frame.
  // Images are decoded *after* runApp() so the main thread is never blocked
  // before the first render.
  runApp(
    ChangeNotifierProvider.value(
      value: appModel,
      child: Chess(),
    ),
  );

  // Preload only the logo synchronously (single tiny image for splash).
  // Piece images load asynchronously; appModel.imagesReady gates navigation.
  await _preloadLogoImage();

  // Load essential piece images and audio in the background.
  // When done, notify listeners so the play buttons re-enable.
  _loadFlameAssetsAsync(prefs.pieceTheme, appModel);

  // Sign in to Play Games Services silently on startup
  PlayGamesService.instance.signInSilently();

  // Check for Google Play Store updates on Android
  InAppUpdateService.instance.checkForUpdate();
}

/// Preloads logo.png into Flutter's image cache (single small image — fast).
Future<void> _preloadLogoImage() async {
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
}

/// Decodes essential piece images and audio, then signals [appModel.imagesReady].
/// Each image decode yields to the event loop so the UI thread stays responsive.
Future<void> _loadFlameAssetsAsync(
    String activeTheme, AppModel appModel) async {
  final List<String> essentialImages = [];
  for (var theme in {activeTheme, 'Classic'}) {
    for (var color in ['black', 'white']) {
      for (var piece in ['king', 'queen', 'rook', 'bishop', 'knight', 'pawn']) {
        essentialImages
            .add('pieces/${formatPieceTheme(theme)}/${piece}_$color.png');
      }
    }
  }

  // Load each image individually with an event-loop yield between decodes.
  for (final img in essentialImages) {
    try {
      await Flame.images.load(img);
    } catch (_) {}
    await Future.delayed(Duration.zero);
  }

  // Load audio assets (fast — small files)
  await FlameAudio.audioCache.loadAll([
    'piece_moved.mp3',
    'win.wav',
    'lose.wav',
    'tie.wav',
  ]);

  // Signal that navigation to ChessView is now safe.
  appModel.imagesReady = true;
  appModel.update();

  // Preload remaining piece themes in the background after a startup delay.
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
        for (final img in themeImages) {
          await Flame.images.load(img);
          // Yield to the event loop between each decode so the UI thread can
          // process frames rather than running all 12 decodes back-to-back.
          await Future.delayed(Duration.zero);
        }
        // Small pause between themes
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
