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
                    // ── Top App Bar (Color Toggle, Centered Piece Name, Close Button) ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          // Left Wing: Color Switcher aligned to far left
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildColorToggle(highlightColor),
                            ),
                          ),

                          // Center Wing: Exactly in the middle of the screen
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
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

                          // Right Wing: Close Button aligned to far right (equal weight to Left Wing)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Tooltip(
                                message: 'Close',
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.12),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: theme.lightTile,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Hero Section (Piece Graphic) ──
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: RepaintBoundary(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.94, end: 1.0)
                                      .animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              key: ValueKey(
                                  '$_selectedPiece-$_selectedColor-$pieceTheme'),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Container(
                                decoration: _selectedColor == 'black'
                                    ? BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.lightTile
                                                .withValues(alpha: 0.28),
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
                      ),
                    ),

                    // ── Horizontal Piece Selector Bar ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 10.0,
                      ),
                      child: SingleChildScrollView(
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
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Description Glass Panel ──
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: RepaintBoundary(
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                    // Header Row: Summary & Points Pill Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tactical Role Tag
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Text(
                                  info.role.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        theme.lightTile.withValues(alpha: 0.85),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                info.summary,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE5E2E1),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: highlightColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: highlightColor.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: highlightColor.withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            info.valueText,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: highlightColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Movement Pattern Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: highlightColor.withValues(alpha: 0.15),
                              border: Border.all(
                                color: highlightColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.navigation_rounded,
                              size: 16,
                              color: highlightColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MOVEMENT PATTERN',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    color:
                                        theme.lightTile.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  info.movePattern,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFE5E2E1),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Detailed Explanation Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Text(
                        info.details,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: Color(0xFFC3C8C2),
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Strategy / Combat Tip Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.withValues(alpha: 0.15),
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'STRATEGY & TACTICS',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: Colors.amber,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  info.combatTip,
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.88),
                                    height: 1.45,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Special Rules Card (Castling, En Passant, Promotion, Leaping)
                    if (info.specialRule != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: highlightColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: highlightColor.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: 18,
                              color: highlightColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (info.specialRuleTitle != null) ...[
                                    Text(
                                      info.specialRuleTitle!,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: highlightColor,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    info.specialRule!,
                                    textAlign: TextAlign.justify,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      height: 1.45,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
