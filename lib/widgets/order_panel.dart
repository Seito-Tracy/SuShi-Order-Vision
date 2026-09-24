import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sushi_models.dart';

class OrderPanel extends StatefulWidget {
  final bool isLeft;
  final List<MenuItem?> slots;
  final void Function(MenuItem item) onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onConfirm;
  final VoidCallback onClose;

  const OrderPanel({
    super.key,
    required this.isLeft,
    required this.slots,
    required this.onAdd,
    required this.onRemove,
    required this.onConfirm,
    required this.onClose,
  });

  @override
  State<OrderPanel> createState() => _OrderPanelState();
}

class _OrderPanelState extends State<OrderPanel> {
  int _catIndex = 0;
  int _catPage = 0;
  int _itemPage = 0;

  void _selectCategory(int index) {
    setState(() {
      _catIndex = index;
      _itemPage = 0;
    });
  }

  void _addItem(MenuItem item) {
    widget.onAdd(item);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (ctx, t, child) {
        final dx = (widget.isLeft ? -1.0 : 1.0) * (1 - t) * 0.3;
        return Opacity(
          opacity: t,
          child: FractionalTranslation(
            translation: Offset(dx, 0.03 * (1 - t)),
            child: child,
          ),
        );
      },
      child: _buildPanel(),
    );
  }

  Widget _buildPanel() {
    final body = [
      Expanded(flex: 4, child: _buildKeypad()),
      const SizedBox(width: 12),
      Expanded(flex: 1, child: _buildSlotsColumn()),
    ];
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: widget.isLeft ? const Radius.circular(24) : Radius.zero,
          topRight: widget.isLeft ? Radius.zero : const Radius.circular(24),
          bottomLeft: const Radius.circular(24),
          bottomRight: const Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 40,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: widget.isLeft ? body : body.reversed.toList()),
      ),
    );
    final tabColumn = SizedBox(
      width: 40,
      child: Align(alignment: Alignment.topCenter, child: _buildCloseTab()),
    );
    return Container(
      margin: const EdgeInsets.all(10),
      child: SizedBox.expand(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.isLeft
              ? [Expanded(child: card), tabColumn]
              : [tabColumn, Expanded(child: card)],
        ),
      ),
    );
  }

  Widget _buildCloseTab() {
    final left = widget.isLeft;
    return Material(
      color: const Color(0xFFE74C3C),
      borderRadius: BorderRadius.horizontal(
        left: left ? Radius.zero : const Radius.circular(14),
        right: left ? const Radius.circular(14) : Radius.zero,
      ),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onClose,
        child: const SizedBox(
          width: 40,
          height: 64,
          child: Icon(Icons.close, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return LayoutBuilder(
      builder: (ctx, box) {
        const cols = 4;
        const rows = 2;
        final tabCount = (box.maxWidth / 90).floor().clamp(2, 5);
        final perPage = cols * rows;
        final items = kMenuCategories[_catIndex].items;
        final pageCount = math.max(1, (items.length / perPage).ceil());
        final page = _itemPage.clamp(0, pageCount - 1);

        return Column(
          children: [
            Expanded(
              child: Column(
                children: List.generate(rows, (r) {
                  return Expanded(
                    child: Row(
                      children: List.generate(cols, (c) {
                        final idx = page * perPage + r * cols + c;
                        final item = idx < items.length ? items[idx] : null;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: item == null
                                ? const SizedBox()
                                : _FoodButton(
                                    item: item,
                                    onTap: () => _addItem(item),
                                  ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
            _buildPageNav(page, pageCount),
            const SizedBox(height: 10),
            _buildCategoryTabs(tabCount),
          ],
        );
      },
    );
  }

  Widget _buildPageNav(int page, int pageCount) {
    Widget arrow(IconData icon, bool enabled, VoidCallback onTap) {
      return Opacity(
        opacity: enabled ? 1 : 0.3,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 28, color: const Color(0xFF2D3436)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          arrow(
            Icons.keyboard_arrow_up,
            page > 0,
            () => setState(() => _itemPage = page - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Text(
                '${page + 1} / $pageCount',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ),
          ),
          arrow(
            Icons.keyboard_arrow_down,
            page < pageCount - 1,
            () => setState(() => _itemPage = page + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(int perPage) {
    final cats = kMenuCategories;
    final pages = math.max(1, (cats.length / perPage).ceil());
    final page = _catPage.clamp(0, pages - 1);

    Widget pageArrow(IconData icon, bool enabled, VoidCallback onTap) {
      return IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(
          icon,
          color: enabled ? const Color(0xFF2D3436) : const Color(0xFFCCCCCC),
        ),
      );
    }

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          if (pages > 1)
            pageArrow(
              Icons.chevron_left,
              page > 0,
              () => setState(() => _catPage = page - 1),
            ),
          Expanded(
            child: Row(
              children: List.generate(perPage, (i) {
                final idx = page * perPage + i;
                if (idx >= cats.length) {
                  return const Expanded(child: SizedBox());
                }
                final sel = idx == _catIndex;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: sel
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => _selectCategory(idx),
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: Text(
                            cats[idx].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF636E72),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (pages > 1)
            pageArrow(
              Icons.chevron_right,
              page < pages - 1,
              () => setState(() => _catPage = page + 1),
            ),
        ],
      ),
    );
  }

  Widget _buildSlotsColumn() {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: widget.slots.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) =>
                SizedBox(height: 72, child: _buildSlotCard(i)),
          ),
        ),
        const SizedBox(height: 12),
        _buildConfirmButton(),
      ],
    );
  }

  Widget _buildSlotCard(int i) {
    final item = widget.slots[i];
    if (item == null) {
      return CustomPaint(
        foregroundPainter: _DashedRectPainter(
          color: const Color(0xFFCCCCCC),
          radius: 14,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFFFAFAFA),
          ),
          child: Center(
            child: Text(
              '待選區 ${i + 1}',
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.image != null)
            Image.asset(item.image!, fit: BoxFit.contain)
          else
            Container(color: item.color),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.45, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '¥${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => widget.onRemove(i),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0x88000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    final items = widget.slots.whereType<MenuItem>().toList();
    final count = items.length;
    final total = items.fold<double>(0, (sum, it) => sum + it.price);
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: count > 0 ? widget.onConfirm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE74C3C),
          disabledBackgroundColor: const Color(0xFFF0F2F5),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFFAAAAAA),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            count > 0 ? '下單 · $count 件 · ¥${total.toStringAsFixed(0)}' : '下單',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _FoodButton extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;
  const _FoodButton({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6FA),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: item.color.withValues(alpha: 0.2)),
            if (item.image != null)
              Image.asset(item.image!, fit: BoxFit.contain)
            else
              Container(color: item.color),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '¥${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xCC00B894),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedRectPainter({required this.color, this.radius = 14});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    for (final metric in path.computeMetrics()) {
      double dist = 0;
      bool draw = true;
      const dash = 8.0;
      const gap = 6.0;
      while (dist < metric.length) {
        final len = draw ? dash : gap;
        if (draw) {
          canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        }
        dist += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}
