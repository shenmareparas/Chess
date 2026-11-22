import 'dart:math' as math;
import 'dart:ui' show DisplayFeature, DisplayFeatureType;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/chess_piece.dart';
import '../logic/shared_functions.dart';
import '../model/app_model.dart';
import '../model/app_themes.dart';
import 'components/chess_view/piece_guide/piece_descriptions.dart';
import 'components/chess_view/piece_guide/piece_selector_item.dart';
import 'components/shared/glass_panel.dart';

bool _isFoldableOrWideScreen(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final hasFoldFeature = mediaQuery.displayFeatures.any(
    (f) =>
        f.type == DisplayFeatureType.fold || f.type == DisplayFeatureType.hinge,
  );
  final isLargeOrUnfolded = mediaQuery.size.shortestSide >= 600;
  return (hasFoldFeature || isLargeOrUnfolded) && mediaQuery.size.width >= 560;
}

class PieceGuideView extends StatefulWidget {
  final ChessPieceType initialPiece;

  const PieceGuideView({
    super.key,
    this.initialPiece = ChessPieceType.king,
  });

  @override
  State<PieceGuideView> createState() => _PieceGuideViewState();
}

class _PieceGuideViewState extends State<PieceGuideView> {
  late ChessPieceType _selectedPiece;
  String _selectedColor = 'white'; // 'white' or 'black'
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _selectedPiece = widget.initialPiece;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      final pieceTheme =
          Provider.of<AppModel>(context, listen: false).pieceTheme;
      _precacheImages(pieceTheme);
    }
  }

  void _precacheImages(String pieceTheme) {
    final formattedTheme = formatPieceTheme(pieceTheme);
    for (final piece in pieceGuideOrder) {
      for (final color in ['white', 'black']) {
        precacheImage(
          AssetImage(
            'assets/images/pieces/$formattedTheme/${pieceTypeToString(piece)}_$color.png',
          ),
          context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context, listen: false);

    return Selector<AppModel, (AppTheme, String)>(
      selector: (_, m) => (m.theme, m.pieceTheme),
      builder: (context, data, _) {
        final theme = data.$1;
        final pieceTheme = data.$2;
        final info = pieceDescriptions[_selectedPiece]!;
        final heroAssetPath =
            'assets/images/pieces/${formatPieceTheme(pieceTheme)}/${pieceTypeToString(_selectedPiece)}_$_selectedColor.png';
        final highlightColor = theme.moveHint != Colors.transparent
            ? theme.moveHint
            : theme.lightTile;

        final isWideOrFoldable = _isFoldableOrWideScreen(context);

        if (isWideOrFoldable) {
          final mediaQuery = MediaQuery.of(context);
          DisplayFeature? horizontalFold;
          DisplayFeature? verticalFold;

          for (final feature in mediaQuery.displayFeatures) {
            if (feature.type == DisplayFeatureType.fold ||
                feature.type == DisplayFeatureType.hinge) {
              if (feature.bounds.height >= mediaQuery.size.height * 0.4) {
                verticalFold = feature;
              } else if (feature.bounds.width >= mediaQuery.size.width * 0.4) {
                horizontalFold = feature;
              }
            }
          }

          if (horizontalFold != null && verticalFold == null) {
            return _buildTabletopLayout(
              context: context,
              theme: theme,
              pieceTheme: pieceTheme,
              info: info,
              heroAssetPath: heroAssetPath,
              highlightColor: highlightColor,
              appModel: appModel,
              horizontalFold: horizontalFold,
            );
          }

          return _buildFoldableDualPaneLayout(
            context: context,
            theme: theme,
            pieceTheme: pieceTheme,
            info: info,
            heroAssetPath: heroAssetPath,
            highlightColor: highlightColor,
            appModel: appModel,
            verticalFold: verticalFold,
          );
        }

        return _buildPhoneLayout(
          context: context,
          theme: theme,
          pieceTheme: pieceTheme,
          info: info,
          heroAssetPath: heroAssetPath,
          highlightColor: highlightColor,
          appModel: appModel,
        );
      },
    );
  }

  // ── Top Header Bar (Left: Back, Middle: Piece Name, Right: Color Switcher) ──

  Widget _buildTopHeader(
    AppTheme theme,
    PieceInfo info,
    Color highlightColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Row(
        children: [
          // Left Wing: Back button (like in Settings)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: 'Back',
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: theme.lightTile,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // Center Wing: Exactly in the middle of the screen
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              info.name,
              key: ValueKey('title-${info.name}'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFFE5E2E1),
              ),
            ),
          ),

          // Right Wing: Color Switcher aligned to far right
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildColorToggle(highlightColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    AppTheme theme,
    String pieceTheme,
    String heroAssetPath,
  ) {
    return Center(
      child: RepaintBoundary(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: Padding(
            key: ValueKey('$_selectedPiece-$_selectedColor-$pieceTheme'),
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Container(
              decoration: _selectedColor == 'black'
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.lightTile.withValues(alpha: 0.28),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    )
                  : null,
              child: Image.asset(
                heroAssetPath,
                width: 190,
                height: 190,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieceSelector(
    String pieceTheme,
    Color highlightColor,
    AppTheme theme,
    AppModel appModel,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: pieceGuideOrder.map((pieceType) {
          final isSelected = pieceType == _selectedPiece;
          return PieceSelectorItem(
            type: pieceType,
            isSelected: isSelected,
            pieceTheme: pieceTheme,
            pieceColor: _selectedColor,
            activeRingColor: highlightColor,
            glowColor: theme.lightTile,
            onTap: () {
              if (_selectedPiece != pieceType) {
                appModel.haptic.selection();
                setState(() {
                  _selectedPiece = pieceType;
                });
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDescriptionPanel(AppTheme theme, Color highlightColor) {
    return RepaintBoundary(
      child: GlassPanel(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(18, 18, 8, 18),
        color: const Color(0x80201F1F),
        child: SizedBox.expand(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _PieceDescriptionCard(
              key: ValueKey(_selectedPiece),
              piece: _selectedPiece,
              theme: theme,
              highlightColor: highlightColor,
            ),
          ),
        ),
      ),
    );
  }

  // ── Closed Mode Layout (Standard Phone / Folded Outer Screen) ──

  Widget _buildPhoneLayout({
    required BuildContext context,
    required AppTheme theme,
    required String pieceTheme,
    required PieceInfo info,
    required String heroAssetPath,
    required Color highlightColor,
    required AppModel appModel,
  }) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background Gradient with Dot Grid ──
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(gradient: theme.background),
              child: CustomPaint(
                painter: DotGridPainter(
                  color: theme.lightTile.withValues(alpha: 0.05),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Bar: Left Back, Middle Name, Right Color Switcher ──
                _buildTopHeader(theme, info, highlightColor),

                // ── Hero Section (Piece Graphic) ──
                Expanded(
                  flex: 4,
                  child: _buildHeroSection(theme, pieceTheme, heroAssetPath),
                ),

                // ── Horizontal Piece Selector Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0,
                  ),
                  child: _buildPieceSelector(
                    pieceTheme,
                    highlightColor,
                    theme,
                    appModel,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Description Glass Panel ──
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildDescriptionPanel(theme, highlightColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Open Mode Layout (Unfolded Foldable Screen / Wide Viewport) ──

  Widget _buildFoldableDualPaneLayout({
    required BuildContext context,
    required AppTheme theme,
    required String pieceTheme,
    required PieceInfo info,
    required String heroAssetPath,
    required Color highlightColor,
    required AppModel appModel,
    required DisplayFeature? verticalFold,
  }) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Background Gradient with Dot Grid ──
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(gradient: theme.background),
              child: CustomPaint(
                painter: DotGridPainter(
                  color: theme.lightTile.withValues(alpha: 0.05),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;
                      final safePaddingLeft = mediaQuery.padding.left;

                      double? leftPaneWidth;
                      double? rightPaneWidth;
                      double hingeGap = 16.0;

                      if (verticalFold != null) {
                        final hingeLeftInView =
                            verticalFold.bounds.left - safePaddingLeft;
                        final hingeRightInView =
                            verticalFold.bounds.right - safePaddingLeft;

                        if (hingeLeftInView > 250 &&
                            hingeRightInView < totalWidth - 250) {
                          leftPaneWidth = math.max(
                            240.0,
                            hingeLeftInView - 16.0 - 10.0,
                          );
                          hingeGap = math.max(
                            16.0,
                            (hingeRightInView - hingeLeftInView) + 16.0,
                          );
                          rightPaneWidth = math.max(
                            260.0,
                            totalWidth - leftPaneWidth - hingeGap,
                          );
                        }
                      }

                      // Left side screen:
                      // left back, middle chess piece name, right color switcher,
                      // hero graphic, piece selector
                      final leftPane = SizedBox(
                        width: leftPaneWidth,
                        child: Column(
                          children: [
                            _buildTopHeader(theme, info, highlightColor),
                            Expanded(
                              child: _buildHeroSection(
                                theme,
                                pieceTheme,
                                heroAssetPath,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 10.0,
                              ),
                              child: _buildPieceSelector(
                                pieceTheme,
                                highlightColor,
                                theme,
                                appModel,
                              ),
                            ),
                          ],
                        ),
                      );

                      // Right side screen:
                      // whole content
                      final rightPane = SizedBox(
                        width: rightPaneWidth,
                        child: _buildDescriptionPanel(
                          theme,
                          highlightColor,
                        ),
                      );

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (leftPaneWidth != null)
                            leftPane
                          else
                            Expanded(flex: 46, child: leftPane),
                          SizedBox(width: hingeGap),
                          if (rightPaneWidth != null)
                            rightPane
                          else
                            Expanded(flex: 54, child: rightPane),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabletop / Flex Mode Layout (Horizontal Crease) ──

  Widget _buildTabletopLayout({
    required BuildContext context,
    required AppTheme theme,
    required String pieceTheme,
    required PieceInfo info,
    required String heroAssetPath,
    required Color highlightColor,
    required AppModel appModel,
    required DisplayFeature horizontalFold,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final safePaddingTop = mediaQuery.padding.top;
    final hingeTopInView = horizontalFold.bounds.top - safePaddingTop;
    final hingeBottomInView = horizontalFold.bounds.bottom - safePaddingTop;
    final hingeHeight = math.max(
      16.0,
      (hingeBottomInView - hingeTopInView) + 12.0,
    );

    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(gradient: theme.background),
              child: CustomPaint(
                painter: DotGridPainter(
                  color: theme.lightTile.withValues(alpha: 0.05),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Screen (Hero & Selector with Header)
                Expanded(
                  child: Column(
                    children: [
                      _buildTopHeader(theme, info, highlightColor),
                      Expanded(
                        child: _buildHeroSection(
                          theme,
                          pieceTheme,
                          heroAssetPath,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        child: _buildPieceSelector(
                          pieceTheme,
                          highlightColor,
                          theme,
                          appModel,
                        ),
                      ),
                    ],
                  ),
                ),

                // Crease gap
                SizedBox(height: hingeHeight),

                // Bottom Screen (Description Panel - whole content)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildDescriptionPanel(theme, highlightColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorToggle(Color highlightColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'White Pieces',
            child: _colorCircle(
              colorVal: Colors.white,
              isSelected: _selectedColor == 'white',
              highlightColor: highlightColor,
              onTap: () {
                if (_selectedColor != 'white') {
                  setState(() => _selectedColor = 'white');
                }
              },
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Black Pieces',
            child: _colorCircle(
              colorVal: const Color(0xFF18181B),
              isSelected: _selectedColor == 'black',
              highlightColor: highlightColor,
              onTap: () {
                if (_selectedColor != 'black') {
                  setState(() => _selectedColor = 'black');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorCircle({
    required Color colorVal,
    required bool isSelected,
    required Color highlightColor,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      minimumSize: Size.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colorVal,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? highlightColor
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: highlightColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}

class _PieceDescriptionCard extends StatefulWidget {
  final ChessPieceType piece;
  final AppTheme theme;
  final Color highlightColor;

  const _PieceDescriptionCard({
    super.key,
    required this.piece,
    required this.theme,
    required this.highlightColor,
  });

  @override
  State<_PieceDescriptionCard> createState() => _PieceDescriptionCardState();
}

class _PieceDescriptionCardState extends State<_PieceDescriptionCard> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final canScroll = maxScroll > 8 && currentScroll < maxScroll - 16;
    if (canScroll != _canScrollDown) {
      setState(() => _canScrollDown = canScroll);
    }
  }

  void _checkScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final canScroll = maxScroll > 8 && currentScroll < maxScroll - 16;
    if (canScroll != _canScrollDown) {
      setState(() => _canScrollDown = canScroll);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = pieceDescriptions[widget.piece]!;
    final theme = widget.theme;
    final highlightColor = widget.highlightColor;
    final isKing = widget.piece == ChessPieceType.king;

    return Align(
      alignment: Alignment.topCenter,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _checkScroll();
          return false;
        },
        child: Stack(
          children: [
            RawScrollbar(
              thumbVisibility: true,
              trackVisibility: false,
              thickness: 3.0,
              radius: const Radius.circular(8),
              padding: const EdgeInsets.only(
                top: 4,
                bottom: 12,
                right: 0,
              ),
              thumbColor: theme.lightTile.withValues(alpha: 0.35),
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(2, 0, 12, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header: Role Tag & Material Value Pill ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Tactical Role Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            info.role.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: theme.lightTile.withValues(alpha: 0.9),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),

                        // Material Value Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isKing
                                ? Colors.amber.withValues(alpha: 0.16)
                                : highlightColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isKing
                                  ? Colors.amber.withValues(alpha: 0.45)
                                  : highlightColor.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isKing
                                    ? Colors.amber.withValues(alpha: 0.25)
                                    : highlightColor.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isKing
                                    ? Icons.workspace_premium_rounded
                                    : Icons.diamond_outlined,
                                size: 14,
                                color: isKing ? Colors.amber : highlightColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                info.valueText,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isKing ? Colors.amber : highlightColor,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Summary Description ──
                    Text(
                      info.summary,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE5E2E1),
                        height: 1.45,
                      ),
                    ),

                    // ── Quick Spec Chips ──
                    if (info.quickStats.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: info.quickStats.map((stat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.09),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 4.5,
                                  height: 4.5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        highlightColor.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  stat,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        theme.lightTile.withValues(alpha: 0.82),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 16),

                    // ── Movement & Mechanics ──
                    Row(
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          size: 15,
                          color: highlightColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MOVEMENT & MECHANICS',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: highlightColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      info.movePattern,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF1F0EF),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      info.details,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xFFC3C8C2),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 16),

                    // ── Grandmaster Strategy ──
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_rounded,
                          size: 15,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'GRANDMASTER STRATEGY',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      info.combatTip,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    // ── Special Rules & Key Powers ──
                    if (info.specialRules.isNotEmpty ||
                        info.specialRule != null) ...[
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            size: 15,
                            color: Color(0xFF818CF8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (info.specialRuleTitle ?? 'SPECIAL RULES & POWERS')
                                .toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: Color(0xFF818CF8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (info.specialRules.isNotEmpty)
                        ...info.specialRules.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final rule = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(top: idx > 0 ? 10.0 : 0.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    rule.icon,
                                    size: 15,
                                    color: const Color(0xFFA5B4FC),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rule.title,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFE5E2E1),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        rule.description,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: Color(0xFFC3C8C2),
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                      else
                        Text(
                          info.specialRule!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFFC3C8C2),
                            height: 1.45,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // Subtle bottom fade gradient to indicate content continues below
            if (_canScrollDown)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 38,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0x80201F1F).withValues(alpha: 0.0),
                          const Color(0x80201F1F).withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // "MORE INFO" scroll affordance badge
            if (_canScrollDown)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () {
                      _scrollController.animateTo(
                        (_scrollController.offset + 120).clamp(
                          0.0,
                          _scrollController.position.maxScrollExtent,
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'MORE INFO',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: theme.lightTile,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: theme.lightTile,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
