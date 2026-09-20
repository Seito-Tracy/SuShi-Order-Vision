import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sushi_models.dart';

/// 左右两侧待选区槽位（4 格）。
///
/// 用法：
/// - 读：`ref.watch(orderSlotsProvider(isLeft))`
/// - 写：`ref.read(orderSlotsProvider(isLeft).notifier).drop(0, item)`
class OrderSlotsNotifier extends FamilyNotifier<List<MenuItem?>, bool> {
  @override
  List<MenuItem?> build(bool isLeft) => List<MenuItem?>.filled(4, null);

  /// 拖拽放入指定槽位。
  void drop(int idx, MenuItem item) {
    if (idx < 0 || idx >= state.length) return;
    state = [...state]..[idx] = item;
  }

  /// 清空指定槽位。
  void clearSlot(int idx) {
    if (idx < 0 || idx >= state.length) return;
    state = [...state]..[idx] = null;
  }

  /// 加入第一个空槽（无空槽则忽略）。
  void addItem(MenuItem item) {
    final idx = state.indexOf(null);
    if (idx < 0) return;
    state = [...state]..[idx] = item;
  }

  /// 清空全部槽位（下单成功后调用）。
  void clearAll() {
    state = List<MenuItem?>.filled(4, null);
  }

  /// 已选数量。
  int get count => state.whereType<MenuItem>().length;
}

final orderSlotsProvider =
    NotifierProvider.family<OrderSlotsNotifier, List<MenuItem?>, bool>(
      OrderSlotsNotifier.new,
    );
