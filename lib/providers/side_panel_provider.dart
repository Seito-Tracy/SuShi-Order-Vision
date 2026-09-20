import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 左右侧点菜面板的开关状态。
class SidePanelNotifier extends FamilyNotifier<bool, bool> {
  @override
  bool build(bool isLeft) => false;

  void open() => state = true;
  void close() => state = false;
  void toggle() => state = !state;
}

final sidePanelProvider =
    NotifierProvider.family<SidePanelNotifier, bool, bool>(
      SidePanelNotifier.new,
    );
