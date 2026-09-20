import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/menu_repository.dart';
import '../models/sushi_models.dart';

/// 仓库注入点：测试时可用 overrideWithValue 换成 mock 实现。
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository();
});

/// 完整菜单（Future：模拟网络请求，带缓存——只请求一次）。
final menuProvider = FutureProvider<List<MenuItem>>((ref) async {
  return ref.watch(menuRepositoryProvider).fetchMenu();
});

/// 分类菜单。
final menuCategoriesProvider = FutureProvider<List<MenuCategory>>((ref) async {
  return ref.watch(menuRepositoryProvider).fetchCategories();
});
