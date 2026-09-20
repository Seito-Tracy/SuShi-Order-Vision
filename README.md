# SuShi Order Vision

寿司店数字点餐演示应用（Flutter）——双传送带动效点餐、拖拽下单、视频背景，适配条屏 / 平板 / 电视等多种屏幕比例。

包名：`dev.tracytan.sushiordervision`

## 功能

- **双传送带**：左右两条循环传送带，寿司菜品在轨道上流动（转弯、渐隐动画）
- **拖拽点餐**：将传送带上的菜品拖入底部待选区（左右两侧各 4 个槽位），点击已选菜品可移除
- **PLACE ORDER 下单**：实时显示已选数量，确认后进入待确认清单，可汇总合计金额
- **视频背景**：全屏循环播放餐厅氛围视频，左右分屏铺满不变形
- **响应式布局**：全部尺寸按屏幕比例计算（LayoutBuilder + clamp），从 3840×1080 条屏到普通平板/电视均不乱版

## 运行

```bash
flutter pub get
flutter run
```

构建 APK：

```bash
flutter build apk --release
```

## 项目结构

```
lib/
├── app/app.dart                 # 应用入口（MaterialApp）
├── theme/app_theme.dart         # 明暗主题
├── models/sushi_models.dart     # MenuItem / OrderEntry 数据模型
├── screens/home/home_screen.dart # 主屏：传送带区域 + 待选区槽位条
└── widgets/
    ├── conveyor_panel.dart      # 传送带动效
    ├── video_background.dart    # 视频背景
    ├── order_center.dart        # 待确认菜品 / 订单汇总
    └── order_panel.dart         # 分类点菜面板（入口当前隐藏）
```

## 素材

`assets/` 下包含寿司菜品图、传送带贴图、氛围视频与应用图标（`flutter_launcher_icons` 生成 launcher 图标）。
