import 'package:flutter/material.dart';
import '../models/sushi_models.dart';

class OrderCenter extends StatelessWidget {
  final List<MenuItem?> leftSlots;
  final List<MenuItem?> rightSlots;
  final List<OrderEntry> orders;
  final VoidCallback onConfirm;
  final VoidCallback onClearOrders;

  const OrderCenter({
    super.key,
    required this.leftSlots,
    required this.rightSlots,
    required this.orders,
    required this.onConfirm,
    required this.onClearOrders,
  });

  @override
  Widget build(BuildContext context) {
    final pending = [
      ...leftSlots.whereType<MenuItem>(),
      ...rightSlots.whereType<MenuItem>(),
    ];
    final total = orders.fold<double>(0, (s, e) => s + e.item.price * e.qty);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        border: const Border.symmetric(
          vertical: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: Column(
        children: [
          _Header(),
          if (pending.isNotEmpty)
            _PendingSection(pending: pending, onConfirm: onConfirm)
          else
            _EmptyHint(),
          const Divider(color: Color(0xFFEEEEEE), height: 1),
          _OrdersHeader(count: orders.length, onClear: onClearOrders),
          Expanded(child: _OrdersList(orders: orders)),
          _TotalBar(total: total),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: const Column(
        children: [
          Text('🍱', style: TextStyle(fontSize: 40)),
          SizedBox(height: 10),
          Text(
            '點 餐 中 心',
            style: TextStyle(
              color: Color(0xFFE74C3C),
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingSection extends StatelessWidget {
  final List<MenuItem> pending;
  final VoidCallback onConfirm;
  const _PendingSection({required this.pending, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: Text(
            '待確認菜品 (${pending.length})',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: pending.length,
            itemBuilder: (ctx, i) {
              final item = pending[i];
              const sz = 72.0;
              return Container(
                width: sz,
                height: sz,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.55),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.image != null)
                        Image.asset(item.image!, fit: BoxFit.cover)
                      else
                        Container(color: item.color),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                            stops: [0.4, 1.0],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: sz * 0.14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '¥${item.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: sz * 0.125,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '確 認 點 餐',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(Icons.swipe_rounded, color: Color(0xFFCCCCCC), size: 42),
          SizedBox(height: 10),
          Text(
            '將傳送帶上的菜品\n拖拽到下方槽位',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFBBBBBB),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  final int count;
  final VoidCallback onClear;
  const _OrdersHeader({required this.count, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '已點餐品 ($count)',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 16),
          ),
          if (count > 0)
            GestureDetector(
              onTap: onClear,
              child: const Text(
                '清空',
                style: TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<OrderEntry> orders;
  const _OrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          '暫無訂單',
          style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 17),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        final e = orders[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: e.item.color.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: e.item.image != null
                      ? Image.asset(e.item.image!, fit: BoxFit.cover)
                      : Center(
                          child: Text(
                            e.item.emoji,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  e.item.name,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'x${e.qty}',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 18),
              ),
              const SizedBox(width: 4),
              Text(
                '¥${(e.item.price * e.qty).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFFE74C3C),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TotalBar extends StatelessWidget {
  final double total;
  const _TotalBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '合計',
            style: TextStyle(color: Color(0xFF888888), fontSize: 17),
          ),
          Text(
            '¥ ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFFE74C3C),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
