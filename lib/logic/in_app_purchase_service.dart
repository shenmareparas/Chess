import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../model/user_preferences.dart';
import 'ad_service.dart';

/// Singleton service managing Google Play & App Store In-App Purchases (IAP).
/// Handles querying product details, initiating non-consumable purchases,
/// restoring previous purchases, and updating local preferences.
class InAppPurchaseService {
  InAppPurchaseService._();

  static final InAppPurchaseService instance = InAppPurchaseService._();

  static const String removeAdsProductId = 'remove_ads';
  static const Set<String> _productIds = {removeAdsProductId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  UserPreferences? _prefs;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  ProductDetails? _removeAdsProduct;
  ProductDetails? get removeAdsProduct => _removeAdsProduct;

  bool _isPurchasePending = false;
  bool get isPurchasePending => _isPurchasePending;

  /// Notifier to let listeners (e.g. Settings UI) update when products/statuses change.
  final ValueNotifier<bool> purchaseStateNotifier = ValueNotifier<bool>(false);

  /// Initializes the purchase stream listener and loads product metadata.
  Future<void> initialize(UserPreferences prefs) async {
    _prefs = prefs;

    // Sync current pref status with AdService
    AdService.instance.setAdFree(prefs.isAdFree);

    try {
      _isAvailable = await _iap.isAvailable();
    } catch (e) {
      debugPrint('[InAppPurchaseService] isAvailable check failed: $e');
      _isAvailable = false;
    }

    // Always listen to purchase updates
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseDetailsUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        debugPrint('[InAppPurchaseService] Purchase stream error: $error');
        _isPurchasePending = false;
        purchaseStateNotifier.value = !purchaseStateNotifier.value;
      },
    );

    if (_isAvailable) {
      await loadProducts();
    }
  }

  /// Queries the store for product details (e.g. localized price and title).
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    try {
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(_productIds);

      if (response.error != null) {
        debugPrint(
            '[InAppPurchaseService] queryProductDetails error: ${response.error}');
      }

      for (final product in response.productDetails) {
        if (product.id == removeAdsProductId) {
          _removeAdsProduct = product;
        }
      }
      purchaseStateNotifier.value = !purchaseStateNotifier.value;
    } catch (e) {
      debugPrint('[InAppPurchaseService] Failed to query product details: $e');
    }
  }

  /// Launches the native store flow to buy Remove Ads (non-consumable).
  Future<bool> buyRemoveAds() async {
    if (_removeAdsProduct == null) {
      await loadProducts();
    }

    if (_removeAdsProduct == null) {
      debugPrint('[InAppPurchaseService] remove_ads product not found');
      return false;
    }

    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: _removeAdsProduct!);

    _isPurchasePending = true;
    purchaseStateNotifier.value = !purchaseStateNotifier.value;

    try {
      final bool started =
          await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        _isPurchasePending = false;
        purchaseStateNotifier.value = !purchaseStateNotifier.value;
      }
      return started;
    } catch (e) {
      debugPrint('[InAppPurchaseService] buyNonConsumable exception: $e');
      _isPurchasePending = false;
      purchaseStateNotifier.value = !purchaseStateNotifier.value;
      return false;
    }
  }

  /// Restores previous non-consumable purchases made on this store account.
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    _isPurchasePending = true;
    purchaseStateNotifier.value = !purchaseStateNotifier.value;

    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[InAppPurchaseService] restorePurchases exception: $e');
      _isPurchasePending = false;
      purchaseStateNotifier.value = !purchaseStateNotifier.value;
    }
  }

  /// Handles stream updates for purchases.
  Future<void> _onPurchaseDetailsUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.productID == removeAdsProductId) {
        if (purchaseDetails.status == PurchaseStatus.pending) {
          _isPurchasePending = true;
        } else {
          _isPurchasePending = false;

          if (purchaseDetails.status == PurchaseStatus.purchased ||
              purchaseDetails.status == PurchaseStatus.restored) {
            // Unlock ad-free & unlimited undos
            await _unlockAdFree();
          } else if (purchaseDetails.status == PurchaseStatus.error) {
            debugPrint(
                '[InAppPurchaseService] Purchase error: ${purchaseDetails.error}');
          } else if (purchaseDetails.status == PurchaseStatus.canceled) {
            debugPrint('[InAppPurchaseService] Purchase canceled');
          }

          // Complete transaction with store so it's not redelivered repeatedly
          if (purchaseDetails.pendingCompletePurchase) {
            try {
              await _iap.completePurchase(purchaseDetails);
            } catch (e) {
              debugPrint(
                  '[InAppPurchaseService] completePurchase exception: $e');
            }
          }
        }
      }
    }
    purchaseStateNotifier.value = !purchaseStateNotifier.value;
  }

  Future<void> _unlockAdFree() async {
    if (_prefs != null) {
      await _prefs!.setIsAdFree(true);
    }
    AdService.instance.setAdFree(true);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    purchaseStateNotifier.dispose();
  }
}
