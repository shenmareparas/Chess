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

  @override
  void initState() {
    super.initState();
    _selectedPiece = widget.initialPiece;
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
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
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
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.92, end: 1.0)
                                    .animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            key: ValueKey(
                                '$_selectedPiece-$_selectedColor-$pieceTheme'),
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                                filterQuality: FilterQuality.medium,
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
                        child: GlassPanel(
                          borderRadius: 24,
                          padding: const EdgeInsets.all(20),
                          color: const Color(0x80201F1F),
                          child: SizedBox.expand(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              layoutBuilder: (currentChild, previousChildren) =>
                                  Stack(
                                alignment: Alignment.topLeft,
                                children: [
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              ),
                              child: Align(
                                key: ValueKey(_selectedPiece),
                                alignment: Alignment.topLeft,
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Header Row: Summary & Points Pill Badge
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              info.summary,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFE5E2E1),
                                                height: 1.45,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: highlightColor.withValues(
                                                  alpha: 0.16),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: highlightColor
                                                    .withValues(alpha: 0.35),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              info.valueText,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: highlightColor,
                                                letterSpacing: 0.4,
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
                                          color: Colors.white
                                              .withValues(alpha: 0.04),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.08),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: highlightColor
                                                    .withValues(alpha: 0.15),
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
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'MOVEMENT PATTERN',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 0.8,
                                                      color: theme.lightTile
                                                          .withValues(
                                                              alpha: 0.7),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    info.movePattern,
                                                    style: const TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w600,
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

                                      // Detailed Explanation
                                      Text(
                                        info.details,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          color: Color(0xFFC3C8C2),
                                          height: 1.5,
                                        ),
                                      ),

                                      // Special Rules Card (Castling, En Passant, Promotion, Leaping)
                                      if (info.specialRule != null) ...[
                                        const SizedBox(height: 14),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: highlightColor.withValues(
                                                alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: highlightColor.withValues(
                                                  alpha: 0.25),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.stars_rounded,
                                                size: 18,
                                                color: highlightColor,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (info.specialRuleTitle !=
                                                        null) ...[
                                                      Text(
                                                        info.specialRuleTitle!,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: highlightColor,
                                                          letterSpacing: 0.3,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                    ],
                                                    Text(
                                                      info.specialRule!,
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.85),
                                                        height: 1.45,
                                                        fontWeight:
                                                            FontWeight.w400,
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
