import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/sushi_models.dart';
import '../../widgets/conveyor_panel.dart';
import '../../widgets/order_panel.dart';
import '../../widgets/video_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/order_slots_provider.dart';
import '../../providers/side_panel_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 底部选餐区+功能区显示开关
  static const bool _showBottomBars = true;

  // 当前正在拖拽的菜品来源侧（true: 左半区, false: 右半区, null: 无）
  bool? _draggingSide;

  void _openPanel(bool isLeft) =>
      ref.read(sidePanelProvider(isLeft).notifier).open();

  void _closePanel(bool isLeft) =>
      ref.read(sidePanelProvider(isLeft).notifier).close();

  int _panelAdd(bool isLeft, MenuItem item) =>
      ref.read(orderSlotsProvider(isLeft).notifier).addItem(item);

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

  void _onClear(bool isLeft, int idx) =>
      ref.read(orderSlotsProvider(isLeft).notifier).clearSlot(idx);

  void _onQty(bool isLeft, int idx, int delta) =>
      ref.read(orderSlotsProvider(isLeft).notifier).changeQty(idx, delta);

  void _onConfirm(bool isLeft) {
    final notifier = ref.read(orderSlotsProvider(isLeft).notifier);
    final count = notifier.count;
    if (count > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            '點餐成功',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            '已下單 $count 件菜品',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                '確定',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
      notifier.clearAll();
    }
  }

  Widget _buildBeltArea() {
    return LayoutBuilder(
      builder: (ctx, box) {
        final W = box.maxWidth;
        final H = box.maxHeight;
        final dishSz = (H * 0.46).clamp(60.0, W * 0.14);
        final barH = dishSz * 0.78;
        final barW = W * 0.5 * 0.67;
        final btnW = barH * 0.68;
        // 可用宽度 = 选区宽 - 条内边距12 - 按钮+间隔 - 槽行边距20 - 5槽×margin8
        final rawSz = (barW - btnW - 80) / 5;
        final slotSz = rawSz.clamp(10.0, barH * 0.95);

        Widget bar(bool isLeft) {
          final halfW = W / 2;
          final inset = ((halfW - barW) / 2).clamp(12.0, 78.0);
          return Positioned(
            bottom: 41,
            left: isLeft ? inset : null,
            right: isLeft ? null : inset,
            width: barW,
            height: barH,
            child: _SlotBar(
              isLeft: isLeft,
              isHighlighted: _draggingSide == isLeft,
              slots: ref.watch(orderSlotsProvider(isLeft)),
              slotSz: slotSz,
              btnW: btnW,
              barH: barH,
              onAddItem: (item) => _panelAdd(isLeft, item),
              onClear: (i) => _onClear(isLeft, i),
              onQty: (i, d) => _onQty(isLeft, i, d),
              onConfirm: () => _onConfirm(isLeft),
              onOpenPanel: () => _openPanel(isLeft),
            ),
          );
        }

        final barInset = ((W / 2 - barW) / 2).clamp(12.0, 78.0);
        final midGapW = W - 2 * (barInset + barW);
        return Stack(
          children: [
            ConveyorBelt(
              isLeft: true,
              horizontalOnly: true,
              bottomReserved: barH + 55,
              onDishDragStart: (isDishLeft, item) {
                setState(() => _draggingSide = isDishLeft);
              },
              onDishDragEnd: () {
                setState(() => _draggingSide = null);
              },
            ),
            if (_showBottomBars) ...[
              Positioned(
                bottom: 41,
                left: (W - midGapW * 0.8) / 2,
                width: midGapW * 0.8,
                height: barH,
                child: _FuncPanel(
                  barH: barH,
                  onOpenLeftMenu: () => _openPanel(true),
                  onOpenRightMenu: () => _openPanel(false),
                ),
              ),
              bar(true),
              bar(false),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSidePanelOverlay(bool isLeft) {
    final slots = ref.watch(orderSlotsProvider(isLeft));
    final menuSlots = List<MenuItem?>.generate(
      slots.length,
      (i) => slots[i]?.item,
    );
    return Positioned.fill(
      child: Align(
        alignment: isLeft ? Alignment.bottomLeft : Alignment.bottomRight,
        child: FractionallySizedBox(
          widthFactor: 0.45,
          heightFactor: 0.85,
          child: RepaintBoundary(
            child: OrderPanel(
              isLeft: isLeft,
              slots: menuSlots,
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
          if (ref.watch(sidePanelProvider(true))) _buildSidePanelOverlay(true),
          if (ref.watch(sidePanelProvider(false)))
            _buildSidePanelOverlay(false),
        ],
      ),
    );
  }
}

class _SlotBar extends StatefulWidget {
  final bool isLeft;
  final bool isHighlighted;
  final List<OrderEntry?> slots;
  final double slotSz;
  final double btnW;
  final double barH;
  final int Function(MenuItem) onAddItem;
  final void Function(int) onClear;
  final void Function(int, int) onQty;
  final VoidCallback onConfirm;
  final VoidCallback onOpenPanel;

  const _SlotBar({
    required this.isLeft,
    this.isHighlighted = false,
    required this.slots,
    required this.slotSz,
    required this.btnW,
    required this.barH,
    required this.onAddItem,
    required this.onClear,
    required this.onQty,
    required this.onConfirm,
    required this.onOpenPanel,
  });

  @override
  State<_SlotBar> createState() => _SlotBarState();
}

class _SlotBarState extends State<_SlotBar> {
  final ScrollController _scrollController = ScrollController();
  double _lastSlotWidth = 0.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final viewportW = _scrollController.position.viewportDimension;
      final slotW = _lastSlotWidth;
      if (slotW <= 0) return;

      final slotCenter = index * slotW + slotW / 2;
      final targetOffset = (slotCenter - viewportW / 2).clamp(0.0, maxScroll);
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _SlotBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当有新槽位增加时自动定位到最新菜品
    if (widget.slots.length > oldWidget.slots.length) {
      final lastFilled = widget.slots.lastIndexWhere((e) => e != null);
      if (lastFilled >= 0) {
        _scrollToIndex(lastFilled);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.slots.whereType<OrderEntry>().fold(
      0,
      (sum, e) => sum + e.qty,
    );
    final button = SizedBox(
      width: widget.btnW,
      height: widget.barH,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: widget.onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 168, 26),
            foregroundColor: const Color.fromARGB(255, 46, 12, 0),
            elevation: 6,
            shadowColor: const Color(0xFF8A4A00),
            surfaceTintColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
                        fontSize: widget.barH * 0.12,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF210000),
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: widget.barH * 0.02),
                    Text(
                      'ORDER',
                      style: TextStyle(
                        fontSize: widget.barH * 0.13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF210000),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: widget.barH * 0.08),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF210000),
                  borderRadius: BorderRadius.circular(widget.barH * 0.1),
                ),
                child: Text(
                  '$itemCount ITEM${itemCount == 1 ? '' : 'S'}',
                  style: TextStyle(
                    fontSize: widget.barH * 0.1,
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

    Widget buildSlotsArea(double availableW) {
      final slotW = availableW / 5;
      _lastSlotWidth = slotW;
      final count = widget.slots.length;
      final totalW = math.max(availableW, count * slotW);

      return SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: totalW,
          child: Row(
            children: [
              for (var i = 0; i < count; i++)
                SizedBox(width: slotW, child: _buildSlot(i, widget.slotSz)),
            ],
          ),
        ),
      );
    }

    return DragTarget<MenuItem>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final targetIndex = widget.onAddItem(details.data);
        _scrollToIndex(targetIndex);
      },
      builder: (ctx, candidates, rejected) {
        final isHovering = candidates.isNotEmpty;
        final showOverlay = widget.isHighlighted || isHovering;

        return Container(
          height: widget.barH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeInOutCubic,
              height: widget.barH,
              decoration: BoxDecoration(
                color: const Color(0xBFFFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: showOverlay
                      ? const Color(0xFFE8343B)
                      : const Color(0x99FFFFFF),
                  width: showOverlay ? 3.0 : 1.0,
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: widget.isLeft
                          ? [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) =>
                                        buildSlotsArea(constraints.maxWidth),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              button,
                            ]
                          : [
                              button,
                              const SizedBox(width: 8),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) =>
                                        buildSlotsArea(constraints.maxWidth),
                                  ),
                                ),
                              ),
                            ],
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: AnimatedOpacity(
                        opacity: showOverlay ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeInOutCubic,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Drag and drop your item here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.barH * 0.17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlot(int i, double sz) {
    final entry = widget.slots[i];
    final item = entry?.item;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Expanded(
            child: item != null
                ? GestureDetector(
                    onTap: () => widget.onClear(i),
                    child: Padding(
                      padding: EdgeInsets.only(top: sz * 0.05),
                      child: ClipRect(
                        clipper: _VerticalOnlyClipper(),
                        child: Transform.scale(
                          scale: 2.2,
                          child: item.image != null
                              ? Image.asset(item.image!, fit: BoxFit.contain)
                              : Container(color: item.color),
                        ),
                      ),
                    ),
                  )
                : _EmptyPlate(sz: sz, hover: false),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.zero,
            child: Container(
              height: sz * 0.41,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB30C),
                borderRadius: BorderRadius.circular(sz * 0.06),
                border: Border.all(color: const Color(0xFF8B5A2B), width: 0.5),
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 60,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: sz * 0.05),
                      child: Center(
                        child: Text(
                          item?.name ?? 'Please select item',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: sz * (item != null ? 0.10 : 0.10),
                            color: const Color(0xFF331B07),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    color: const Color(0x33331B07),
                    margin: EdgeInsets.symmetric(horizontal: sz * 0.06),
                  ),
                  Expanded(
                    flex: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 254),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(sz * 0.06),
                          bottomRight: Radius.circular(sz * 0.06),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _qtyBtn(
                              Icons.remove,
                              sz,
                              entry != null ? () => widget.onQty(i, -1) : null,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: sz * 0.06,
                              ),
                              child: SizedBox(
                                height: sz * 0.13,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${entry?.qty ?? 0}',
                                    style: TextStyle(
                                      fontSize: sz * 0.15,
                                      color: const Color(0xFF331B07),
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _qtyBtn(
                              Icons.add,
                              sz,
                              entry != null ? () => widget.onQty(i, 1) : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, double sz, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: sz * 0.12,
        height: sz * 0.12,
        margin: EdgeInsets.symmetric(horizontal: sz * 0.03),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFEEB442) : const Color(0xFFC4C4C4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: sz * 0.08, color: Colors.white),
      ),
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

class _EmptyPlate extends StatelessWidget {
  final double sz;
  final bool hover;
  const _EmptyPlate({required this.sz, required this.hover});

  @override
  Widget build(BuildContext context) {
    const grad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE2CCAD),
        Color(0xFFF8B24B),
      ], // 226,204,173 → 248,178,75
    );
    final w = sz * 0.85;
    final h = sz * 0.28;
    final totalH = h * 1.15;
    final wideRect = Rect.fromLTWH(0, totalH - 1.12 * h, w, h);
    final footRect = Rect.fromLTWH(
      w * 0.15,
      totalH - 0.76 * h,
      w * 0.70,
      h * 0.74,
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: w,
        height: totalH,
        child: CustomPaint(
          painter: _PlatePainter(
            wide: wideRect,
            foot: footRect,
            gradient: grad,
            stroke: hover ? const Color(0xFFE74C3C) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PlatePainter extends CustomPainter {
  final Rect wide;
  final Rect foot;
  final Gradient gradient;
  final Color stroke;
  _PlatePainter({
    required this.wide,
    required this.foot,
    required this.gradient,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final union = Path.combine(
      PathOperation.union,
      Path()..addOval(wide),
      Path()..addOval(foot),
    );
    canvas.drawPath(
      union,
      Paint()..shader = gradient.createShader(union.getBounds()),
    );
    canvas.drawPath(
      union,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = stroke,
    );
  }

  @override
  bool shouldRepaint(_PlatePainter oldDelegate) => oldDelegate.stroke != stroke;
}

class _FuncPanel extends StatelessWidget {
  final double barH;
  final VoidCallback onOpenLeftMenu;
  final VoidCallback onOpenRightMenu;
  const _FuncPanel({
    required this.barH,
    required this.onOpenLeftMenu,
    required this.onOpenRightMenu,
  });

  static const Color _dark = Color(0xFF331B07);
  static const Color _yellow = Color(0xFFFFB400);
  static const Color _red = Color(0xFFE8343B);

  void _todo(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('TODO: $label'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _funcBtn(
    String label, {
    VoidCallback? onTap,
    IconData? icon,
    Color bg = _yellow,
    Color fg = _dark,
    String? sub,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: icon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: barH * 0.16, color: fg),
                        SizedBox(width: barH * 0.03),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: barH * 0.125,
                            color: fg,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: barH * 0.125,
                            color: fg,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (sub != null)
                          Text(
                            sub,
                            style: TextStyle(
                              fontSize: barH * 0.095,
                              color: fg,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _openMenuBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: barH * 0.72,
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _dark, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt_rounded, size: barH * 0.22, color: _dark),
            SizedBox(height: barH * 0.03),
            Text(
              'OPEN',
              style: TextStyle(
                fontSize: barH * 0.12,
                color: _dark,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            SizedBox(height: barH * 0.02),
            Text(
              'MENU',
              style: TextStyle(
                fontSize: barH * 0.12,
                color: _dark,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF211509),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        children: [
          _openMenuBtn(onOpenLeftMenu),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _funcBtn(
                        'ORDER HISTORY',
                        onTap: () => _todo(context, 'ORDER HISTORY'),
                      ),
                      _funcBtn(
                        'CHECK OUT',
                        onTap: () => _todo(context, 'CHECK OUT'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _funcBtn(
                        'LANGUAGE',
                        sub: '語言',
                        onTap: () => _todo(context, 'LANGUAGE'),
                      ),
                      _funcBtn(
                        'CALL STAFF',
                        bg: _red,
                        fg: Colors.white,
                        icon: Icons.notifications_active_rounded,
                        onTap: () => _todo(context, 'CALL STAFF'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _openMenuBtn(onOpenRightMenu),
        ],
      ),
    );
  }
}
