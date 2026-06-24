import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Singleton service that manages Google Mobile Ads lifecycle.
///
/// Handles initialization, preloading, and displaying of [RewardedInterstitialAd]
/// for the "1 Ad = 1 Undo" mechanic. All heavy AdMob logic is contained here,
/// keeping it cleanly separated from UI views.
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
      // TODO: Replace with your production iOS ad unit ID before release.
      return 'ca-app-pub-3940256099942544/6978759866';
    }
    throw UnsupportedError('Unsupported platform for ads.');
  }

  // ── State ──

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isLoading = false;
  bool _isInitialized = false;

  // ── Initialization ──

  /// Initializes the Mobile Ads SDK and pre-loads the first ad.
  /// Must be called once in [main()] after [WidgetsFlutterBinding.ensureInitialized()].
  Future<void> initialize() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
    _loadAd();
  }

  // ── Ad Loading ──

  void _loadAd() {
    if (_isLoading || _rewardedInterstitialAd != null) return;
    _isLoading = true;

    RewardedInterstitialAd.load(
      adUnitId: _rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isLoading = false;
          debugPrint('[AdService] Rewarded interstitial ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _rewardedInterstitialAd = null;
          debugPrint(
              '[AdService] Failed to load rewarded interstitial ad: $error');
        },
      ),
    );
  }

  // ── Ad Display ──

  /// Shows the preloaded rewarded interstitial ad.
  ///
  /// [onRewardEarned] is called when the user has fully watched the ad and
  /// earns the reward. After the ad closes (or fails), the next ad is
  /// automatically preloaded so it is ready for future requests.
  ///
  /// [onAdNotAvailable] is called if no ad is loaded yet, allowing the UI
  /// to show appropriate feedback to the user.
  void showRewardedUndoAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdNotAvailable,
  }) {
    if (_rewardedInterstitialAd == null) {
      debugPrint('[AdService] No ad available yet, triggering preload.');
      _loadAd();
      onAdNotAvailable?.call();
      return;
    }

    final ad = _rewardedInterstitialAd!;
    _rewardedInterstitialAd = null; // Consume the loaded ad.

    bool rewardEarned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Ad dismissed. Preloading next ad.');
        ad.dispose();
        _loadAd(); // Preload the next ad eagerly.
        if (rewardEarned) {
          onRewardEarned();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint(
            '[AdService] Ad failed to show: $error. Preloading next ad.');
        ad.dispose();
        _loadAd(); // Preload next even after failure.
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

  /// Whether a rewarded ad is currently preloaded and ready to show.
  bool get isAdLoaded => _rewardedInterstitialAd != null;
}
