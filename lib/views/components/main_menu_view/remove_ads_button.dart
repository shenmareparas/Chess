import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_ui/material_ui.dart';

import '../../../logic/in_app_purchase_service.dart';
import '../../../model/app_model.dart';
import '../shared/glass_panel.dart';

/// Top-left button on MainMenuView that triggers the Remove Ads purchase flow.
/// Automatically hides itself when ads have already been removed.
class RemoveAdsButton extends StatefulWidget {
  final AppModel appModel;

  const RemoveAdsButton(this.appModel, {Key? key}) : super(key: key);

  @override
  State<RemoveAdsButton> createState() => _RemoveAdsButtonState();
}

class _RemoveAdsButtonState extends State<RemoveAdsButton> {
  late final FToast _fToast;

  @override
  void initState() {
    super.initState();
    _fToast = FToast()..init(context);
    InAppPurchaseService.instance.purchaseStateNotifier
        .addListener(_onPurchaseStateChanged);
  }

  @override
  void dispose() {
    InAppPurchaseService.instance.purchaseStateNotifier
        .removeListener(_onPurchaseStateChanged);
    super.dispose();
  }

  void _onPurchaseStateChanged() {
    if (mounted) setState(() {});
  }

  void _showToast(String message) {
    final theme = widget.appModel.theme;
    _fToast.removeCustomToast();
    _fToast.showToast(
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(milliseconds: 2500),
      child: GlassPanel(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: const Color(0x90201F1F),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: theme.lightTile,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE5E2E1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context) {
    final theme = widget.appModel.theme;
    final iapService = InAppPurchaseService.instance;
    final product = iapService.removeAdsProduct;
    final String priceLabel = product?.price ?? 'Buy';

    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassPanel(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              color: const Color(0x80201F1F),
              animation: anim1,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.lightTile.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: theme.lightTile,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Unlimited Undos Pack',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5E2E1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Permanently unlock unlimited undos\n& remove all ads.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFC3C8C2),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC3C8C2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Buy Button
                        Expanded(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              widget.appModel.haptic.light();
                              final success = await iapService.buyRemoveAds();
                              if (!success && !widget.appModel.isAdFree) {
                                _showToast('Purchase unavailable or canceled.');
                              }
                            },
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: theme.lightTile,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                priceLabel,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.darkTile,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1.drive(CurveTween(curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appModel.isAdFree) {
      return const SizedBox.shrink();
    }

    final theme = widget.appModel.theme;
    final iapService = InAppPurchaseService.instance;
    final isPending = iapService.isPurchasePending;

    final bgTop = theme.background?.colors.first ?? const Color(0xFF0A0F0C);
    final isDarkBg =
        ThemeData.estimateBrightnessForColor(bgTop) == Brightness.dark;
    final defaultColor =
        isDarkBg ? const Color(0xFFC3C8C2) : const Color(0xFF313030);

    return Tooltip(
      message: 'Unlimited Undos Pack',
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: isPending
            ? null
            : () {
                widget.appModel.haptic.light();
                _showPurchaseDialog(context);
              },
        child: isPending
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(defaultColor),
                ),
              )
            : Icon(
                Icons.workspace_premium_rounded,
                color: defaultColor,
                size: 24,
              ),
      ),
    );
  }
}
