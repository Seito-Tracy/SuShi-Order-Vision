import '../models/sushi_models.dart';

/// 菜单数据仓库。
///
/// 目前返回本地硬编码数据（kMenu / kMenuCategories），
/// 接入后端后只需把实现换成 HTTP 请求，UI 与 provider 层不用动。
class MenuRepository {
  Future<List<MenuItem>> fetchMenu() async => kMenu;

  Future<List<MenuCategory>> fetchCategories() async => kMenuCategories;
}
