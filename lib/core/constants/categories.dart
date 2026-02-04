import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SpendCategory {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const SpendCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class Categories {
  Categories._();

  static const List<SpendCategory> all = [
    SpendCategory(
      key: '외식',
      label: '외식',
      icon: Icons.restaurant,
      color: AppColors.chipFood,
    ),
    SpendCategory(
      key: '교통',
      label: '교통',
      icon: Icons.directions_bus,
      color: AppColors.chipTransport,
    ),
    SpendCategory(
      key: '쇼핑',
      label: '쇼핑',
      icon: Icons.shopping_bag,
      color: AppColors.chipShopping,
    ),
    SpendCategory(
      key: '편의점',
      label: '편의점',
      icon: Icons.store,
      color: AppColors.chipConvenience,
    ),
    SpendCategory(
      key: '온라인쇼핑',
      label: '온라인쇼핑',
      icon: Icons.laptop,
      color: AppColors.chipOnline,
    ),
    SpendCategory(
      key: '마트',
      label: '마트',
      icon: Icons.shopping_cart,
      color: AppColors.chipMart,
    ),
    SpendCategory(
      key: '기타',
      label: '기타',
      icon: Icons.more_horiz,
      color: AppColors.chipEtc,
    ),
  ];

  static SpendCategory findByKey(String key) {
    return all.firstWhere(
      (c) => c.key == key,
      orElse: () => all.last,
    );
  }
}
