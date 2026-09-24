import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sushi_models.dart';

class ConveyorBelt extends StatefulWidget {
  final bool isLeft;
  final double bottomReserved;
  final bool horizontalOnly;
  final void Function(bool isLeft, MenuItem item)? onDishDragStart;
  final VoidCallback? onDishDragEnd;

  const ConveyorBelt({
    super.key,
    required this.isLeft,
    this.bottomReserved = 0,
    this.horizontalOnly = false,
    this.onDishDragStart,
    this.onDishDragEnd,
  });
  @override
  State<ConveyorBelt> createState() => _ConveyorBeltState();
}

class _BeltDish {
  final String id;
  final MenuItem item;
  double progress;
  _BeltDish(this.id, this.item, this.progress);
}

class _ConveyorBeltState extends State<ConveyorBelt>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  DateTime _lastTime = DateTime.now();
  final _rng = Random();
  int _nextId = 0;
  final List<_BeltDish> _dishes = [];

  static const double _speed = 0.06;
  double _extraSpeed = 0.0;
  double _gap = 0.20;
  double _beltScroll = 0.0;
  bool _firstBuild = true;

  // 交互状态与无触碰恢复机制（3秒无操作恢复运行）
  static const Duration _pauseDuration = Duration(seconds: 3);
  bool _isInteracting = false;
  DateTime? _pauseUntil;

  void _onInteractionStart() {
    _isInteracting = true;
    _pauseUntil = DateTime.now().add(_pauseDuration);
    _extraSpeed = 0.0;
  }

  void _onInteractionEnd() {
    _isInteracting = false;
    _pauseUntil = DateTime.now().add(_pauseDuration);
  }

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_tick)
          ..repeat();
  }

  void _maintainDishes() {
    _dishes.removeWhere((d) => d.progress > 1.6 || d.progress < -0.4);
    if (_dishes.isEmpty) return;

    _dishes.sort((a, b) => a.progress.compareTo(b.progress));

    // 前端补充
    while (_dishes.first.progress > -0.15) {
      _dishes.insert(
        0,
        _BeltDish(
          '${_nextId++}',
          kMenu[_rng.nextInt(kMenu.length)],
          _dishes.first.progress - _gap,
        ),
      );
    }

    // 后端补充
    while (_dishes.last.progress < 1.15) {
      _dishes.add(
        _BeltDish(
          '${_nextId++}',
          kMenu[_rng.nextInt(kMenu.length)],
          _dishes.last.progress + _gap,
        ),
      );
    }
  }

  void _applyProgressDelta(double dProgress) {
    if (dProgress == 0.0) return;
    setState(() {
      for (final d in _dishes) {
        d.progress += dProgress;
      }
      _beltScroll += dProgress;
      _maintainDishes();
    });
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    final dt = now.difference(_lastTime).inMicroseconds / 1e6;
    _lastTime = now;
    final cd = dt.clamp(0.0, 0.1);

    final isPaused =
        _isInteracting || (_pauseUntil != null && now.isBefore(_pauseUntil!));
    final baseSpeed = isPaused ? 0.0 : _speed;
    final eff = baseSpeed + _extraSpeed;

    if (eff != 0.0) {
      setState(() {
        for (final d in _dishes) {
          d.progress += eff * cd;
        }
        _beltScroll += eff * cd;
        _extraSpeed *= exp(-3.5 * cd);
        if (_extraSpeed.abs() < 0.003) _extraSpeed = 0.0;
        _maintainDishes();
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    _onInteractionStart();
  }

  void _onPanUpdate(DragUpdateDetails details, double totalLen) {
    if (totalLen <= 0) return;
    _onInteractionStart();
    final dir = widget.isLeft ? -1.0 : 1.0;
    final dProgress = (details.delta.dx * dir) / totalLen;
    _applyProgressDelta(dProgress);
  }

  void _onPanEnd(DragEndDetails details, double totalLen) {
    _onInteractionEnd();
    final v = details.velocity.pixelsPerSecond;
    if (v.dx.abs() > 150 && totalLen > 0) {
      final dir = widget.isLeft ? -1.0 : 1.0;
      final progressVelocity = (v.dx * dir) / totalLen;
      _extraSpeed = progressVelocity.clamp(-0.8, 0.8);
    } else {
      _extraSpeed = 0.0;
    }
  }

  void _onPanCancel() {
    _onInteractionEnd();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _calcTurnY(double W, double H) {
    final effectiveH = H - widget.bottomReserved;
    final defaultTurnY = effectiveH * 0.39;
    if (widget.horizontalOnly) {
      final s = W / 4300.0;
      final curMachineBottom = defaultTurnY + 523.0 * s;
      final bottomGap = effectiveH - curMachineBottom;
      // 在平板等垂直高度充裕的机型上，若机器悬空过高，则平滑下沉靠近底部；TV 机型 100% 维持原样
      if (bottomGap > 523.0 * s * 0.25) {
        final targetBottom =
            effectiveH - (widget.bottomReserved > 0 ? 15.0 : 35.0);
        final dropTurnY = targetBottom - 523.0 * s;
        return max(defaultTurnY, dropTurnY);
      }
    }
    return defaultTurnY;
  }

  double _calcDishSz(double W, double H) {
    if (widget.horizontalOnly) {
      final s = W / 4300.0;
      final machineH = 702.0 * s;
      // 限制盘子尺寸与传送带机身比例协调，精致适中
      final maxSz = (machineH * 1.02) / 1.75;
      final baseSz = (H * 0.42).clamp(42.0, W * 0.105);
      return min(baseSz, maxSz);
    }
    return (H * 0.42).clamp(54.0, W * 0.125);
  }

  Offset _pos(double progress, double W, double H, double sz) {
    final turnY = _calcTurnY(W, H);

    if (widget.horizontalOnly) {
      final s = W / 4300.0;
      final imgH = sz * 1.75;
      final imgW = imgH * (1200 / 896);
      final span = W + 2 * imgW;
      final t = progress.clamp(0.0, 1.0);
      final x = widget.isLeft ? W + imgW - t * span : -imgW + t * span;
      final beltCenterY = turnY + 15.0 * s;
      return Offset(x, beltCenterY - 0.58 * imgH);
    }

    final laneX = widget.isLeft ? W - sz / 2 : sz / 2;
    final vertLen = H - turnY + sz; // enter from below to turn point
    final horzLen = W;
    final total = vertLen + horzLen;
    final pTurn = vertLen / total;

    if (progress <= pTurn) {
      final t = progress / pTurn;
      final centerY = H + sz - t * (H - turnY + sz);
      return Offset(laneX - sz / 2, centerY - sz / 2);
    } else {
      final t = ((progress - pTurn) / (1 - pTurn)).clamp(0.0, 2.0);
      final dx = widget.isLeft ? -(t * horzLen) : (t * horzLen);
      return Offset(laneX - sz / 2 + dx, turnY - sz / 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, box) {
        final W = box.maxWidth;
        final H = box.maxHeight;
        final sz = _calcDishSz(W, H);
        final imgH = sz * 1.75;
        final imgW = imgH * (1200 / 896);
        final dishW = widget.horizontalOnly ? imgW : sz;
        final dishH = widget.horizontalOnly ? imgH : sz;

        final turnY = _calcTurnY(W, H);
        final vertLen = H - turnY + sz;
        final horzLen = W;
        final totalLen = widget.horizontalOnly
            ? W + 2 * imgW
            : vertLen + horzLen;
        _gap = ((widget.horizontalOnly ? 0.82 * imgW : sz) + 6) / totalLen;

        // Reposition initial dishes with correct gap on first build
        if (_firstBuild) {
          _firstBuild = false;
          _dishes.clear();
          double p = -0.15;
          while (p < 1.15) {
            _dishes.add(
              _BeltDish('${_nextId++}', kMenu[_rng.nextInt(kMenu.length)], p),
            );
            p += _gap;
          }
        }

        final children = <Widget>[];

        if (widget.horizontalOnly) {
          final s = W / 4300.0;
          final machineH = 702.0 * s;
          final beltH = 226.0 * s;
          final tileW = 6683.0 * s;
          final machineTop = turnY - 179.0 * s;
          final beltTop = turnY + 15.0 * s - beltH / 2;
          final tiles = (W / tileW).ceil() + 2;
          final shift = -((_beltScroll * (W + 2 * imgW)) % tileW);

          children.add(
            Positioned(
              left: 0,
              top: machineTop,
              width: W,
              height: machineH,
              child: Image.asset(
                'assets/belt/belt_machine.png',
                fit: BoxFit.fill,
              ),
            ),
          );
          children.add(
            Positioned(
              left: 0,
              top: beltTop,
              width: W,
              height: beltH,
              child: ClipRect(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (int i = 0; i < tiles; i++)
                      Positioned(
                        left: i * tileW + shift,
                        top: 0,
                        width: tileW,
                        height: beltH,
                        child: Image.asset(
                          'assets/belt/seamless_belt.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        children.addAll(
          _dishes.map((d) {
            final pos = _pos(d.progress, W, H, sz);
            final labelTop = dishH * 0.075;
            final isDishLeft = (pos.dx + dishW / 2) < (W / 2);
            return Positioned(
              key: ValueKey(d.id),
              left: pos.dx,
              top: pos.dy,
              width: dishW,
              height: dishH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: labelTop,
                    left: dishW * 0.175,
                    right: dishW * 0.175,
                    child: IgnorePointer(
                      child: _BeltLabel(item: d.item, w: dishW, h: dishH),
                    ),
                  ),
                  LongPressDraggable<MenuItem>(
                    delay: const Duration(milliseconds: 250),
                    data: d.item,
                    onDragStarted: () {
                      _onInteractionStart();
                      widget.onDishDragStart?.call(isDishLeft, d.item);
                    },
                    onDragEnd: (_) {
                      _onInteractionEnd();
                      widget.onDishDragEnd?.call();
                    },
                    onDraggableCanceled: (_, _) {
                      _onInteractionEnd();
                      widget.onDishDragEnd?.call();
                    },
                    feedback: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: 0.9,
                        child: _DishCard(item: d.item, sz: dishH * 0.85),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.25,
                      child: _DishCard(item: d.item, sz: dishH),
                    ),
                    child: _DishCard(item: d.item, sz: dishH),
                  ),
                ],
              ),
            );
          }),
        );

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _onInteractionStart(),
          onPointerUp: (_) => _onInteractionEnd(),
          onPointerCancel: (_) => _onInteractionEnd(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _onPanStart,
            onPanUpdate: (d) => _onPanUpdate(d, totalLen),
            onPanEnd: (d) => _onPanEnd(d, totalLen),
            onPanCancel: _onPanCancel,
            child: Container(
              color: Colors.transparent,
              child: Stack(clipBehavior: Clip.none, children: children),
            ),
          ),
        );
      },
    );
  }
}

class _BeltLabel extends StatelessWidget {
  final MenuItem item;
  final double w;
  final double h;
  const _BeltLabel({required this.item, required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    final fs = h * 0.062;
    return Container(
      height: h * 0.17,
      decoration: BoxDecoration(
        color: const Color.fromARGB(220, 255, 255, 255),
        borderRadius: BorderRadius.circular(h * 0.025),
        border: Border.all(
          color: const Color.fromARGB(255, 170, 155, 122),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04),
              child: Center(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF2D3436),
                    fontSize: fs,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(h * 0.025),
              ),
              child: Container(
                color: const Color.fromARGB(255, 242, 217, 179),
                alignment: Alignment.center,
                child: Text(
                  '¥${item.price.toStringAsFixed(0)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF2D3436),
                    fontSize: fs * 0.9,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  final MenuItem item;
  final double sz;
  const _DishCard({required this.item, required this.sz});
  @override
  Widget build(BuildContext context) {
    if (item.image != null) {
      return Image.asset(
        item.image!,
        width: sz * (1200 / 896),
        height: sz,
        fit: BoxFit.contain,
      );
    }
    return Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(sz * 0.16),
      ),
    );
  }
}
