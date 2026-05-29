import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Constantes ─────────────────────────────────────────────────────────────

const _kDiceTypes = [4, 6, 8, 10, 12, 20, 100];

Color _diceColor(int sides) {
  switch (sides) {
    case 4:   return const Color(0xFF9C27B0);
    case 6:   return const Color(0xFF1E88E5);
    case 8:   return const Color(0xFF00897B);
    case 10:  return const Color(0xFF43A047);
    case 12:  return const Color(0xFFE65100);
    case 20:  return const Color(0xFFE53935);
    case 100: return const Color(0xFFD81B60);
    default:  return Colors.grey;
  }
}

// ── Point d'entrée ─────────────────────────────────────────────────────────

void showDiceRollerSheet(BuildContext context) {
  Scaffold.of(context).openEndDrawer();
}

/// Widget à placer comme `endDrawer` d'un Scaffold.
class DiceRollerDrawer extends StatefulWidget {
  const DiceRollerDrawer({super.key});
  @override
  State<DiceRollerDrawer> createState() => _DiceRollerSheetState();
}

class _DiceRollerSheetState extends State<DiceRollerDrawer>
    with TickerProviderStateMixin {
  final Map<int, int> _counts = {for (final d in _kDiceTypes) d: 0};
  List<_DiceResult>? _results;
  final List<_HistoryEntry> _history = [];
  bool _rolling = false;

  // Un contrôleur 3D par type de dé
  late final Map<int, _Die3DController> _dieControllers;

  @override
  void initState() {
    super.initState();
    _dieControllers = {
      for (final d in _kDiceTypes)
        d: _Die3DController(vsync: this, sides: d),
    };
  }

  @override
  void dispose() {
    for (final c in _dieControllers.values) { c.dispose(); }
    super.dispose();
  }

  int get _totalDice => _counts.values.fold(0, (a, b) => a + b);

  void _increment(int sides) =>
      setState(() => _counts[sides] = (_counts[sides]! + 1).clamp(0, 20));
  void _decrement(int sides) =>
      setState(() => _counts[sides] = (_counts[sides]! - 1).clamp(0, 20));
  void _clearAll() => setState(() {
        for (final d in _kDiceTypes) { _counts[d] = 0; }
        _results = null;
      });

  String _buildLabel() => _kDiceTypes
      .where((d) => _counts[d]! > 0)
      .map((d) => '${_counts[d]}d$d')
      .join(' + ');

  Future<void> _roll() async {
    if (_totalDice == 0 || _rolling) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _rolling = true;
      _results = null;
    });

    final rng = Random();
    final results = <_DiceResult>[];

    // Lancer l'animation 3D pour chaque type sélectionné
    final activeDice = _kDiceTypes.where((d) => _counts[d]! > 0).toList();
    for (final d in activeDice) {
      _dieControllers[d]!.startRolling();
    }

    // Attendre la fin des animations
    await Future.delayed(const Duration(milliseconds: 1000));

    // Calculer les résultats finaux
    for (final d in _kDiceTypes) {
      for (int i = 0; i < _counts[d]!; i++) {
        results.add(_DiceResult(sides: d, value: rng.nextInt(d) + 1));
      }
    }

    // Atterrissage : montrer les résultats finaux sur les dés
    for (final d in activeDice) {
      final vals = results.where((r) => r.sides == d).map((r) => r.value).toList();
      final total = vals.fold(0, (s, v) => s + v);
      _dieControllers[d]!.land(total > 0 ? total : rng.nextInt(d) + 1);
    }

    if (!mounted) return;
    setState(() {
      _results = results;
      _rolling = false;
      if (results.isNotEmpty) {
        _history.insert(
          0,
          _HistoryEntry(
            label: _buildLabel(),
            total: results.fold(0, (s, r) => s + r.value),
            details: results.map((r) => 'd${r.sides}:${r.value}').join('  '),
          ),
        );
        if (_history.length > 5) _history.removeLast();
      }
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final activeDice = _kDiceTypes.where((d) => _counts[d]! > 0).toList();
    final width = (MediaQuery.of(context).size.width * 0.88).clamp(0.0, 380.0);

    return Drawer(
      width: width,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── En-tête ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
              child: Row(
                children: [
                  const Text('🎲', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  const Text('Lanceur de dés',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Effacer'),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.white54,
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: Colors.white38,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),

            // ── Zone 3D ───────────────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: activeDice.isEmpty
                  ? const SizedBox.shrink()
                  : _build3DStage(activeDice),
            ),

            // ── Contenu scrollable ────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                children: [
                  _buildDiceGrid(),
                  const SizedBox(height: 16),
                  _buildRollButton(),
                  const SizedBox(height: 20),
                  if (_results != null) ...[
                    _buildResults(),
                    const SizedBox(height: 20),
                  ],
                  if (_history.isNotEmpty) ...[
                    const Text('Historique',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    ..._history.map(_buildHistoryTile),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Zone 3D ──────────────────────────────────────────────────────────────

  Widget _build3DStage(List<int> activeDice) {
    // Taille adaptative selon le nombre de types
    final dieSize = activeDice.length <= 3
        ? 76.0
        : activeDice.length <= 5
            ? 64.0
            : 52.0;
    final stageHeight = dieSize + 48.0;

    return ClipRect(
      child: Container(
        height: stageHeight,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.4),
              Colors.black.withValues(alpha: 0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: activeDice.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, i) {
            final d = activeDice[i];
            return SizedBox(
              width: dieSize + 8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRect(
                    child: SizedBox(
                      width: dieSize,
                      height: dieSize,
                      child: _Die3DWidget(
                        controller: _dieControllers[d]!,
                        size: dieSize,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_counts[d]}×d$d',
                    style: TextStyle(
                      fontSize: 10,
                      color: _diceColor(d).withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Grille des dés ────────────────────────────────────────────────────────

  Widget _buildDiceGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: _kDiceTypes.map(_buildDiceTile).toList(),
    );
  }

  Widget _buildDiceTile(int sides) {
    final count = _counts[sides]!;
    final isSelected = count > 0;
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  _diceColor(sides).withValues(alpha: 0.85),
                  _diceColor(sides).withValues(alpha: 0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? Border.all(color: _diceColor(sides), width: 1.5)
            : Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DiceIcon(sides: sides, size: 32,
              color: isSelected ? Colors.white : Colors.white38),
          const SizedBox(height: 2),
          Text('d$sides',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.white54)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SmallBtn(
                  icon: Icons.remove,
                  onTap: isSelected ? () => _decrement(sides) : null),
              const SizedBox(width: 4),
              Text('$count',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white38)),
              const SizedBox(width: 4),
              _SmallBtn(icon: Icons.add, onTap: () => _increment(sides)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRollButton() {
    final enabled = _totalDice > 0 && !_rolling;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? _roll : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade700,
          disabledBackgroundColor: Colors.white12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _rolling
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Text('🎲', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _totalDice == 0
                          ? 'Sélectionnez des dés'
                          : 'Lancer (${_buildLabel()})',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResults() {
    final results = _results!;
    final total = results.fold(0, (s, r) => s + r.value);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Résultat',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('$total',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: results.map((r) => _ResultChip(result: r)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(_HistoryEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.label,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  Text(entry.details,
                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Text('${entry.total}',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: Colors.amber.shade300)),
          ],
        ),
      ),
    );
  }
}

// ── Contrôleur 3D ───────────────────────────────────────────────────────────

class _Die3DController extends ChangeNotifier {
  final int sides;
  late AnimationController _ctrl;
  int _displayValue;
  bool _isLanded = false;
  double _currentAngle = 0;
  final Random _rng = Random();

  _Die3DController({required TickerProvider vsync, required this.sides})
      : _displayValue = 1 {
    _ctrl = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1000),
    );
    _ctrl.addListener(_onTick);
    _ctrl.addStatusListener(_onStatus);
  }

  int get displayValue => _displayValue;
  double get angle => _currentAngle;
  bool get isLanded => _isLanded;

  void _onTick() {
    final t = _ctrl.value; // 0..1
    // 5 rotations complètes + décélération
    _currentAngle = _easeOutQuart(t) * 5 * 2 * pi;
    // Mettre à jour la valeur affichée aléatoirement sauf en fin
    if (t < 0.85) {
      _displayValue = _rng.nextInt(sides) + 1;
    }
    notifyListeners();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Attendre la méthode land() pour fixer la valeur finale
    }
  }

  double _easeOutQuart(double t) {
    // Accélération rapide puis décélération douce
    if (t < 0.3) {
      return (t / 0.3) * (t / 0.3) * 1.2; // accélération
    } else {
      final s = (t - 0.3) / 0.7;
      return 1.2 - (1 - s) * (1 - s) * (1 - s) * (1 - s) * 1.2 +
          (1 - (1.0)) * 0; // placeholder
    }
  }

  void startRolling() {
    _isLanded = false;
    _ctrl.forward(from: 0);
  }

  void land(int value) {
    _displayValue = value;
    _isLanded = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTick);
    _ctrl.dispose();
    super.dispose();
  }
}

// ── Widget dé 3D ────────────────────────────────────────────────────────────

class _Die3DWidget extends StatelessWidget {
  final _Die3DController controller;
  final double size;

  const _Die3DWidget({required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final angle = controller.angle;
        final value = controller.displayValue;
        final sides = controller.sides;
        final color = _diceColor(sides);
        final isLanded = controller.isLanded;

        // Décompose en rotation Y principale + tangage X
        final yAngle = angle;
        final xTilt = sin(angle * 1.3) * 0.35;

        // Quand cos(yAngle) < 0, le dé est de dos
        final showFront = cos(yAngle) >= 0;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(xTilt)
            ..rotateY(yAngle),
          child: showFront
              ? _buildFace(color, value, sides, isLanded, false)
              : Transform(
                  // Un-miroir la face arrière
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(pi),
                  child: _buildFace(
                      color.withValues(alpha: 0.4), null, sides, isLanded, true),
                ),
        );
      },
    );
  }

  Widget _buildFace(Color color, int? value, int sides, bool landed, bool isBack) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _Die3DFacePainter(
              sides: sides,
              color: color,
              isBack: isBack,
              landed: landed,
            ),
          ),
          if (!isBack)
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (landed)
                      Text(
                        '${value ?? '?'}',
                        style: TextStyle(
                          fontSize: size * 0.38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(blurRadius: 6, color: Colors.black45)
                          ],
                        ),
                      )
                    else ...[
                      Text(
                        '${value ?? '?'}',
                        style: TextStyle(
                          fontSize: size * 0.34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        'd$sides',
                        style: TextStyle(
                          fontSize: size * 0.14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Peintre face 3D (formes distinctes par type) ────────────────────────────

Path _dieShapePath(int sides, Size size) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  final r = size.width * 0.44;
  switch (sides) {
    case 4:  // Triangle pointe en haut
      return _polygonPath(cx, cy + r * 0.08, r, 3, -pi / 2);
    case 6:  // Carré arrondi
      return Path()..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 1.9, height: r * 1.9),
        Radius.circular(r * 0.15),
      ));
    case 8:  // Diamant (carré à 45°)
      return _polygonPath(cx, cy, r, 4, 0);
    case 10: // Pentagone
      return _polygonPath(cx, cy, r, 5, -pi / 2);
    case 12: // Hexagone
      return _polygonPath(cx, cy, r, 6, 0);
    case 20: // Décagone — silhouette de l'icosaèdre vu de dessus
      return _polygonPath(cx, cy, r, 10, -pi / 2);
    case 100:// Cercle
      return Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    default:
      return _polygonPath(cx, cy, r, 6, 0);
  }
}

Path _polygonPath(double cx, double cy, double r, int n, double start) {
  final p = Path();
  for (int i = 0; i < n; i++) {
    final a = start + 2 * pi * i / n;
    final x = cx + r * cos(a);
    final y = cy + r * sin(a);
    i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
  }
  return p..close();
}

class _Die3DFacePainter extends CustomPainter {
  final int sides;
  final Color color;
  final bool isBack;
  final bool landed;
  const _Die3DFacePainter({
    required this.sides, required this.color,
    required this.isBack, required this.landed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _dieShapePath(sides, size);
    if (isBack) {
      canvas.drawPath(path, Paint()
        ..color = color
        ..style = PaintingStyle.fill);
      canvas.drawPath(path, Paint()
        ..color = Colors.white10
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      return;
    }
    // Ombre portée
    canvas.drawShadow(path, color.withValues(alpha: 0.6), 8, false);
    // Remplissage dégradé
    final bounds = path.getBounds();
    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.60)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds)
      ..style = PaintingStyle.fill);
    // Contour
    canvas.drawPath(path, Paint()
      ..color = landed ? Colors.white54 : Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_Die3DFacePainter o) =>
      o.sides != sides || o.color != color || o.isBack != isBack || o.landed != landed;
}

// ── Icône dé (petite tuile grille) ──────────────────────────────────────────

class _DiceIcon extends StatelessWidget {
  final int sides;
  final double size;
  final Color color;
  const _DiceIcon({required this.sides, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DicePainter(sides: sides, color: color),
    );
  }
}

class _DicePainter extends CustomPainter {
  final int sides;
  final Color color;
  _DicePainter({required this.sides, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.44;

    switch (sides) {
      case 4:
        _polygon(canvas, paint, cx, cy, r, 3, -pi / 2);
        _line(canvas, paint, cx, cy - r, cx - r * cos(pi / 6), cy + r / 2);
        _line(canvas, paint, cx, cy - r, cx + r * cos(pi / 6), cy + r / 2);
        break;
      case 6:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy), width: r * 2.1, height: r * 2.1),
            const Radius.circular(5),
          ),
          paint,
        );
        break;
      case 8:
        _polygon(canvas, paint, cx, cy, r, 4, -pi / 4);
        _line(canvas, paint, cx - r * cos(pi / 4), cy, cx + r * cos(pi / 4), cy);
        _line(canvas, paint, cx, cy - r * cos(pi / 4), cx, cy + r * cos(pi / 4));
        break;
      case 10:
        _polygon(canvas, paint, cx, cy, r, 5, -pi / 2);
        break;
      case 12:
        _polygon(canvas, paint, cx, cy, r, 6, 0);
        break;
      case 20:
        _polygon(canvas, paint, cx, cy, r, 10, -pi / 2);
        _polygon(canvas, paint, cx, cy, r * 0.5, 10, -pi / 10);
        break;
      case 100:
        canvas.drawCircle(Offset(cx, cy), r, paint);
        canvas.drawCircle(Offset(cx, cy), r * 0.5, paint);
        break;
    }
  }

  void _polygon(Canvas canvas, Paint paint, double cx, double cy, double r,
      int n, double start) {
    final path = Path();
    for (int i = 0; i < n; i++) {
      final a = start + (2 * pi * i / n);
      final x = cx + r * cos(a);
      final y = cy + r * sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _line(Canvas c, Paint p, double x1, double y1, double x2, double y2) =>
      c.drawLine(Offset(x1, y1), Offset(x2, y2), p);

  @override
  bool shouldRepaint(_DicePainter old) =>
      old.sides != sides || old.color != color;
}

// ── Widgets utilitaires ──────────────────────────────────────────────────────

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _SmallBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white12 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14,
            color: onTap != null ? Colors.white : Colors.white24),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  final _DiceResult result;
  const _ResultChip({required this.result});

  @override
  Widget build(BuildContext context) {
    final isMax = result.value == result.sides;
    final isMin = result.value == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isMax
            ? Colors.amber.withValues(alpha: 0.25)
            : isMin
                ? Colors.red.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMax
              ? Colors.amber.withValues(alpha: 0.6)
              : isMin
                  ? Colors.red.withValues(alpha: 0.5)
                  : Colors.white12,
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'd${result.sides} ',
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
            TextSpan(
              text: '${result.value}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isMax
                    ? Colors.amber
                    : isMin
                        ? Colors.redAccent
                        : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modèles internes ─────────────────────────────────────────────────────────

class _DiceResult {
  final int sides;
  final int value;
  const _DiceResult({required this.sides, required this.value});
}

class _HistoryEntry {
  final String label;
  final int total;
  final String details;
  const _HistoryEntry({required this.label, required this.total, required this.details});
}
