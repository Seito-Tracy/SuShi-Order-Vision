import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/sushi_models.dart';
import '../../widgets/conveyor_panel.dart';
import '../../widgets/order_panel.dart';
import '../../widgets/video_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _leftSlots = List<MenuItem?>.filled(4, null);
  final _rightSlots = List<MenuItem?>.filled(4, null);
  bool _leftPanelOpen = false;
  bool _rightPanelOpen = false;

  void _openPanel(bool isLeft) => setState(() {
    if (isLeft) {
      _leftPanelOpen = true;
    } else {
      _rightPanelOpen = true;
    }
  });

  void _closePanel(bool isLeft) => setState(() {
    if (isLeft) {
      _leftPanelOpen = false;
    } else {
      _rightPanelOpen = false;
    }
  });

  void _panelAdd(bool isLeft, MenuItem item) {
    final slots = isLeft ? _leftSlots : _rightSlots;
    final idx = slots.indexOf(null);
    if (idx >= 0) setState(() => slots[idx] = item);
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onDrop(bool isLeft, int idx, MenuItem item) =>
      setState(() => (isLeft ? _leftSlots : _rightSlots)[idx] = item);

  void _onClear(bool isLeft, int idx) =>
      setState(() => (isLeft ? _leftSlots : _rightSlots)[idx] = null);

  void _onConfirm(bool isLeft) {
    final slots = isLeft ? _leftSlots : _rightSlots;
    final count = slots.whereType<MenuItem>().length;
    if (count > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('點餐成功'),
          content: Text('已下單 $count 件菜品'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('確定'),
            ),
          ],
        ),
      );
      setState(() => slots.fillRange(0, 4, null));
    }
  }

  Widget _buildBeltArea() {
    return LayoutBuilder(
      builder: (ctx, box) {
        final W = box.maxWidth;
        final H = box.maxHeight;
        final dishSz = (H * 0.46).clamp(60.0, W * 0.14);
        final barH = dishSz * 0.72;
        final barW = W * 0.5 * 0.70;
        final btnW = barH * 3 / 4;
        final slotGap = (barH * 0.1).clamp(4.0, 12.0);
        final slotSz = ((barW - btnW - 12 - 3 * slotGap) / 4).clamp(
          30.0,
          barH * 0.95,
        );

        Widget bar(bool isLeft) {
          final halfW = W / 2;
          final inset = ((halfW - barW) / 2).clamp(12.0, 78.0);
          return Positioned(
            bottom: 12,
            left: isLeft ? inset : null,
            right: isLeft ? null : inset,
            width: barW,
            height: barH,
            child: _SlotBar(
              isLeft: isLeft,
              slots: isLeft ? _leftSlots : _rightSlots,
              slotSz: slotSz,
              btnW: btnW,
              barH: barH,
              onDrop: (i, item) => _onDrop(isLeft, i, item),
              onClear: (i) => _onClear(isLeft, i),
              onConfirm: () => _onConfirm(isLeft),
              onOpenPanel: () => _openPanel(isLeft),
            ),
          );
        }

        return Stack(
          children: [
            ConveyorBelt(
              isLeft: true,
              horizontalOnly: true,
              bottomReserved: barH + 26,
            ),
            bar(true),
            bar(false),
          ],
        );
      },
    );
  }

  Widget _buildSidePanelOverlay(bool isLeft) {
    final slots = isLeft ? _leftSlots : _rightSlots;
    return Positioned.fill(
      child: Align(
        alignment: isLeft ? Alignment.bottomLeft : Alignment.bottomRight,
        child: FractionallySizedBox(
          widthFactor: 0.45,
          heightFactor: 0.85,
          child: RepaintBoundary(
            child: OrderPanel(
              isLeft: isLeft,
              slots: slots,
              onAdd: (item) => _panelAdd(isLeft, item),
              onRemove: (i) => _onClear(isLeft, i),
              onConfirm: () {
                _closePanel(isLeft);
                _onConfirm(isLeft);
              },
              onClose: () => _closePanel(isLeft),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const VideoBackground(),
          Column(
            children: [
              const Expanded(flex: 45, child: SizedBox()),
              Expanded(flex: 55, child: _buildBeltArea()),
            ],
          ),
          if (_leftPanelOpen) _buildSidePanelOverlay(true),
          if (_rightPanelOpen) _buildSidePanelOverlay(false),
        ],
      ),
    );
  }
}

class _SlotBar extends StatelessWidget {
  final bool isLeft;
  final List<MenuItem?> slots;
  final double slotSz;
  final double btnW;
  final double barH;
  final void Function(int, MenuItem) onDrop;
  final void Function(int) onClear;
  final VoidCallback onConfirm;
  final VoidCallback onOpenPanel;

  const _SlotBar({
    required this.isLeft,
    required this.slots,
    required this.slotSz,
    required this.btnW,
    required this.barH,
    required this.onDrop,
    required this.onClear,
    required this.onConfirm,
    required this.onOpenPanel,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = slots.whereType<MenuItem>().length;
    final button = SizedBox(
      width: btnW,
      height: barH,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 168, 26),
            foregroundColor: const Color.fromARGB(255, 46, 12, 0),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  children: [
                    Text(
                      'PLACE',
                      style: TextStyle(
                        fontSize: barH * 0.12,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF210000),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'ORDER',
                      style: TextStyle(
                        fontSize: barH * 0.12,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF210000),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: barH * 0.06),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF210000),
                  borderRadius: BorderRadius.circular(barH * 0.1),
                ),
                child: Text(
                  '$itemCount ITEM${itemCount == 1 ? '' : 'S'}',
                  style: TextStyle(
                    fontSize: barH * 0.11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final slotsRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (i) => _buildSlot(i, slotSz)),
    );

    return Container(
      height: barH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: barH,
            decoration: BoxDecoration(
              color: const Color(0xA6FFFFFF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x80FFFFFF)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: isLeft
                    ? [
                        Expanded(child: slotsRow),
                        const SizedBox(width: 8),
                        button,
                      ]
                    : [
                        button,
                        const SizedBox(width: 8),
                        Expanded(child: slotsRow),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlot(int i, double sz) {
    final item = slots[i];
    return DragTarget<MenuItem>(
      onAcceptWithDetails: (d) => onDrop(i, d.data),
      builder: (ctx, candidates, _) {
        final hover = candidates.isNotEmpty;
        return GestureDetector(
          onTap: item != null ? () => onClear(i) : null,
          child: Container(
            width: sz,
            height: sz,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: item != null
                ? Column(
                    children: [
                      Expanded(
                        child: ClipRect(
                          clipper: _VerticalOnlyClipper(),
                          child: Transform.scale(
                            scale: 1.54,
                            child: item.image != null
                                ? Image.asset(item.image!, fit: BoxFit.contain)
                                : Container(color: item.color),
                          ),
                        ),
                      ),
                      SizedBox(height: sz * 0.03),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: sz * 0.15,
                          color: const Color(0xFF2D3436),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(sz * 0.85, sz * 0.85),
                        painter: _DashedCirclePainter(
                          color: hover
                              ? const Color(0xFFE74C3C)
                              : const Color(0xFFDDDDDD),
                          strokeWidth: 2,
                          dashCount: 12,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: sz * 0.32,
                            color: hover
                                ? const Color(0xFFE74C3C)
                                : const Color(0xFFCCCCCC),
                          ),
                          Text(
                            '拖至此處',
                            style: TextStyle(
                              fontSize: sz * 0.14,
                              color: hover
                                  ? const Color(0xFFE74C3C)
                                  : const Color(0xFFBBBBBB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _VerticalOnlyClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(-size.width * 4, 0, size.width * 9, size.height);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldDelegate) => false;
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  _DashedCirclePainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashCount = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final dashAngle = 2 * math.pi / dashCount;
    final dashSpace = dashAngle * 0.5;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle + dashSpace / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle - dashSpace,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      color != oldDelegate.color;
}
