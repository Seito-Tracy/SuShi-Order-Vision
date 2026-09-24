import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sushi_models.dart';

/// 左右两侧待选区槽位（5 格），每格为 null 或 (菜品, 数量)。
///
/// 用法：
/// - 读：`ref.watch(orderSlotsProvider(isLeft))`
/// - 写：`ref.read(orderSlotsProvider(isLeft).notifier).drop(0, item)`
class OrderSlotsNotifier extends FamilyNotifier<List<OrderEntry?>, bool> {
  static const int slotCount = 5;

  @override
  List<OrderEntry?> build(bool isLeft) =>
      List<OrderEntry?>.filled(slotCount, null);

  /// 拖拽放入指定槽位：空位新建、同菜品合并 +1、其他菜品替换。
  void drop(int idx, MenuItem item) {
    if (idx < 0 || idx >= state.length) return;
    final list = [...state];
    final cur = list[idx];
    if (cur != null && cur.item.id == item.id) {
      list[idx] = cur.copyWith(qty: cur.qty + 1);
    } else {
      list[idx] = OrderEntry(item);
    }
    _ensureTrailingEmpty(list);
    state = list;
  }

  /// 加入（拖拽或面板点选）：优先合并同菜品槽位，否则放第一个空槽；超出后自动扩充槽位。
  /// 返回放入或累加的槽位索引。
  int addItem(MenuItem item) {
    final list = [...state];
    final same = list.indexWhere((e) => e?.item.id == item.id);
    if (same >= 0) {
      list[same] = list[same]!.copyWith(qty: list[same]!.qty + 1);
      state = list;
      return same;
    }
    int idx = list.indexOf(null);
    if (idx >= 0) {
      list[idx] = OrderEntry(item);
      _ensureTrailingEmpty(list);
      state = list;
      return idx;
    } else {
      idx = list.length;
      list.add(OrderEntry(item));
      _ensureTrailingEmpty(list);
      state = list;
      return idx;
    }
  }

  /// 数量加减（减到 0 清空槽位）。
  void changeQty(int idx, int delta) {
    if (idx < 0 || idx >= state.length) return;
    final cur = state[idx];
    if (cur == null) return;
    final next = cur.qty + delta;
    final list = [...state];
    list[idx] = next <= 0 ? null : cur.copyWith(qty: next);
    _cleanupTrailingEmptySlots(list);
    state = list;
  }

  /// 清空指定槽位。
  void clearSlot(int idx) {
    if (idx < 0 || idx >= state.length) return;
    final list = [...state]..[idx] = null;
    _cleanupTrailingEmptySlots(list);
    state = list;
  }

  /// 确保末尾始终至少有一个空槽，供后续放入
  void _ensureTrailingEmpty(List<OrderEntry?> list) {
    if (list.isEmpty || list.last != null) {
      list.add(null);
    }
  }

  /// 尾部多余空槽清理（保持至少 slotCount 个，且尾部最多一个空槽）
  void _cleanupTrailingEmptySlots(List<OrderEntry?> list) {
    while (list.length > slotCount &&
        list.last == null &&
        list[list.length - 2] == null) {
      list.removeLast();
    }
  }

  /// 清空全部槽位（下单成功后调用）。
  void clearAll() {
    state = List<OrderEntry?>.filled(slotCount, null);
  }

  /// 已选总数（按数量累计）。
  int get count =>
      state.whereType<OrderEntry>().fold(0, (sum, e) => sum + e.qty);
}

final orderSlotsProvider =
    NotifierProvider.family<OrderSlotsNotifier, List<OrderEntry?>, bool>(
      OrderSlotsNotifier.new,
    );
