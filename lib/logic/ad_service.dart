import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Singleton service that manages Google Mobile Ads lifecycle.
///
/// Handles initialization, preloading, and displaying of [RewardedInterstitialAd]
/// (for the "1 Ad = 1 Undo" mechanic) and standard [InterstitialAd] (for exit
/// match transitions). All heavy AdMob logic is contained here, keeping it
/// cleanly separated from UI views.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  // ── Ad Unit IDs ──

  /// Test App ID for Android: ca-app-pub-3940256099942544~3347511713
  /// Test App ID for iOS:     ca-app-pub-3940256099942544~1458002511
  static String get _rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1620835257397609/5968714376';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/6978759866';
    }
    throw UnsupportedError('Unsupported platform for ads.');
  }

  static String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1620835257397609/9337114716';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    throw UnsupportedError('Unsupported platform for ads.');
  }

  // ── State ──

  RewardedInterstitialAd? _rewardedInterstitialAd;
  DateTime? _rewardedLoadedAt;

  InterstitialAd? _exitInterstitialAd;
  DateTime? _exitInterstitialLoadedAt;

  bool _isLoadingRewarded = false;
  bool _isLoadingInterstitial = false;
  bool _isInitialized = false;

  /// AdMob ads typically expire after 60 minutes.
  /// Discard and reload if older than 50 minutes to avoid stale blank impressions.
  static const Duration _adTtl = Duration(minutes: 50);

  // ── Initialization ──

  /// Initializes the Mobile Ads SDK.
  /// Must be called once in [main()] after [WidgetsFlutterBinding.ensureInitialized()].
  /// Ads are loaded lazily on demand when gameplay begins or free undos run low,
  /// avoiding thousands of wasted ad requests on app launch.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('[AdService] MobileAds initialization error: $e');
    }
  }

  // ── Ad Loading ──

  /// Preloads a rewarded interstitial ad lazily when the user is likely to need one
  /// (e.g. after using their free undo or opening the chess board).
  void preloadRewardedAd() {
    _loadRewardedAd();
  }

  /// Preloads an exit interstitial ad lazily during match play
  /// (e.g. once the first move is made), rather than on app launch.
  void preloadExitInterstitialAd() {
    _loadExitInterstitialAd();
  }

  void _loadRewardedAd() {
    if (!_isInitialized) return;

    // Check if current ad is still fresh
    if (_rewardedInterstitialAd != null) {
      if (_rewardedLoadedAt != null &&
          DateTime.now().difference(_rewardedLoadedAt!) < _adTtl) {
        return;
      }
      _rewardedInterstitialAd?.dispose();
      _rewardedInterstitialAd = null;
    }

    if (_isLoadingRewarded) return;
    _isLoadingRewarded = true;

    RewardedInterstitialAd.load(
      adUnitId: _rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _rewardedLoadedAt = DateTime.now();
          _isLoadingRewarded = false;
          debugPrint('[AdService] Rewarded interstitial ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewarded = false;
          _rewardedInterstitialAd = null;
          _rewardedLoadedAt = null;
          debugPrint(
              '[AdService] Failed to load rewarded interstitial ad: $error');
        },
      ),
    );
  }

  void _loadExitInterstitialAd() {
    if (!_isInitialized) return;

    // Check if current ad is still fresh
    if (_exitInterstitialAd != null) {
      if (_exitInterstitialLoadedAt != null &&
          DateTime.now().difference(_exitInterstitialLoadedAt!) < _adTtl) {
        return;
      }
      _exitInterstitialAd?.dispose();
      _exitInterstitialAd = null;
    }

    if (_isLoadingInterstitial) return;
    _isLoadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _exitInterstitialAd = ad;
          _exitInterstitialLoadedAt = DateTime.now();
          _isLoadingInterstitial = false;
          debugPrint('[AdService] Exit interstitial ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          _exitInterstitialAd = null;
          _exitInterstitialLoadedAt = null;
          debugPrint('[AdService] Failed to load exit interstitial ad: $error');
        },
      ),
    );
  }

  // ── Ad Display ──

  /// Shows the preloaded rewarded interstitial ad for undos.
  void showRewardedUndoAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdNotAvailable,
  }) {
    if (_rewardedInterstitialAd == null) {
      debugPrint('[AdService] No rewarded ad available yet, preloading.');
      _loadRewardedAd();
      onAdNotAvailable?.call();
      return;
    }

    final ad = _rewardedInterstitialAd!;
    _rewardedInterstitialAd = null; // Consume loaded ad.

    bool rewardEarned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Rewarded ad dismissed. Preloading next.');
        ad.dispose();
        _loadRewardedAd();
        if (rewardEarned) {
          onRewardEarned();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint(
            '[AdService] Rewarded ad failed to show: $error. Preloading next.');
        ad.dispose();
        _loadRewardedAd();
        onRewardEarned(); // Grant reward anyway to avoid blocking user.
      },
    );

    ad.show(
      onUserEarnedReward: (_, reward) {
        debugPrint(
            '[AdService] User earned reward: ${reward.amount} ${reward.type}');
        rewardEarned = true;
      },
    );
  }

  /// Displays an interstitial ad when the user exits a chess match.
  ///
  /// Frequency capping is controlled server-side via the Google AdMob Console.
  ///
  /// [onAdDismissed] is called when the ad closes, fails to show, or is skipped
  /// due to missing ad readiness or AdMob server capping. This ensures navigation
  /// back to [MainMenuView] is never blocked.
  void showExitInterstitialAd({required VoidCallback onAdDismissed}) {
    if (_exitInterstitialAd == null) {
      debugPrint(
          '[AdService] Exit interstitial ad not ready. Preloading next.');
      _loadExitInterstitialAd();
      onAdDismissed();
      return;
    }

    final ad = _exitInterstitialAd!;
    _exitInterstitialAd = null; // Consume loaded ad.

    bool dismissedCalled = false;
    void safeCallback() {
      if (!dismissedCalled) {
        dismissedCalled = true;
        onAdDismissed();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Exit interstitial ad dismissed.');
        ad.dispose();
        _loadExitInterstitialAd();
        safeCallback();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Exit interstitial ad failed to show: $error.');
        ad.dispose();
        _loadExitInterstitialAd();
        safeCallback();
      },
    );

    ad.show();
  }

  /// Whether a rewarded ad is currently preloaded, non-expired, and ready to show.
  bool get isAdLoaded {
    if (_rewardedInterstitialAd == null) return false;
    if (_rewardedLoadedAt == null) return false;
    return DateTime.now().difference(_rewardedLoadedAt!) < _adTtl;
  }

  /// Whether an exit interstitial ad is currently preloaded, non-expired, and ready to show.
  bool get isExitAdLoaded {
    if (_exitInterstitialAd == null) return false;
    if (_exitInterstitialLoadedAt == null) return false;
    return DateTime.now().difference(_exitInterstitialLoadedAt!) < _adTtl;
  }
}
