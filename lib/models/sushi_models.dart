import 'package:flutter/material.dart';

class MenuItem {
  final String id, name, emoji;
  final String? image;
  final double price;
  final Color color;
  const MenuItem(
    this.id,
    this.name,
    this.emoji,
    this.price,
    this.color, {
    this.image,
  });
}

class ConveyorDish {
  final String uid;
  final MenuItem item;
  double progress;
  ConveyorDish(this.uid, this.item, this.progress);
}

class OrderEntry {
  final MenuItem item;
  int qty;
  OrderEntry(this.item, {this.qty = 1});

  OrderEntry copyWith({int? qty}) => OrderEntry(item, qty: qty ?? this.qty);
}

const List<MenuItem> kMenu = [
  MenuItem(
    '1',
    '三文魚握壽司',
    '🍣',
    18.0,
    Color(0xFFE17055),
    image: 'assets/sushi_items/item_01.png',
  ),
  MenuItem(
    '2',
    '金槍魚握壽司',
    '🐟',
    22.0,
    Color(0xFFD63031),
    image: 'assets/sushi_items/item_02.png',
  ),
  MenuItem(
    '3',
    '章魚小丸子',
    '🐙',
    15.0,
    Color(0xFF6C5CE7),
    image: 'assets/sushi_items/item_03.png',
  ),
  MenuItem(
    '4',
    '炸蝦天婦羅',
    '🍤',
    20.0,
    Color(0xFFFF7675),
    image: 'assets/sushi_items/item_04.png',
  ),
  MenuItem(
    '5',
    '玉子燒',
    '🥚',
    12.0,
    Color(0xFFFDCB6E),
    image: 'assets/sushi_items/item_05.png',
  ),
  MenuItem(
    '6',
    '海膽軍艦',
    '🌟',
    35.0,
    Color(0xFF00B894),
    image: 'assets/sushi_items/item_06.png',
  ),
  MenuItem(
    '7',
    '蟹肉沙拉',
    '🦀',
    28.0,
    Color(0xFFFF6B81),
    image: 'assets/sushi_items/item_01.png',
  ),
  MenuItem(
    '8',
    '扇貝壽司',
    '🐚',
    16.0,
    Color(0xFF74B9FF),
    image: 'assets/sushi_items/item_02.png',
  ),
  MenuItem(
    '9',
    '鰻魚握壽司',
    '🐠',
    30.0,
    Color(0xFFA29BFE),
    image: 'assets/sushi_items/item_03.png',
  ),
  MenuItem(
    '10',
    '味噌湯',
    '🍵',
    8.0,
    Color(0xFF55EFC4),
    image: 'assets/sushi_items/item_04.png',
  ),
  MenuItem(
    '11',
    '龍蝦刺身',
    '🦞',
    48.0,
    Color(0xFFFF4757),
    image: 'assets/sushi_items/item_05.png',
  ),
  MenuItem(
    '12',
    '茶碗蒸',
    '🍶',
    10.0,
    Color(0xFFECCC68),
    image: 'assets/sushi_items/item_06.png',
  ),
];

class MenuCategory {
  final String name;
  final List<MenuItem> items;
  const MenuCategory(this.name, this.items);
}

final kMenuCategories = <MenuCategory>[
  MenuCategory('人氣推薦', [
    kMenu[0],
    kMenu[1],
    kMenu[3],
    kMenu[5],
    kMenu[8],
    kMenu[10],
    kMenu[2],
    kMenu[4],
    kMenu[7],
  ]),
  MenuCategory('握壽司', [kMenu[0], kMenu[1], kMenu[8], kMenu[7]]),
  MenuCategory('軍艦卷物', [kMenu[5], kMenu[6], kMenu[7]]),
  MenuCategory('熟食小食', [kMenu[2], kMenu[3], kMenu[4], kMenu[11]]),
  MenuCategory('刺身沙拉', [kMenu[6], kMenu[10], kMenu[1], kMenu[0], kMenu[9]]),
  MenuCategory('湯品蒸物', [kMenu[9], kMenu[11], kMenu[4]]),
  MenuCategory('雙人套餐', [
    kMenu[0],
    kMenu[1],
    kMenu[2],
    kMenu[3],
    kMenu[4],
    kMenu[5],
    kMenu[6],
    kMenu[7],
    kMenu[8],
    kMenu[9],
    kMenu[10],
    kMenu[11],
  ]),
  MenuCategory('主廚特選', [
    kMenu[10],
    kMenu[5],
    kMenu[8],
    kMenu[1],
    kMenu[6],
    kMenu[3],
    kMenu[0],
    kMenu[2],
    kMenu[4],
    kMenu[7],
    kMenu[9],
    kMenu[11],
  ]),
];
