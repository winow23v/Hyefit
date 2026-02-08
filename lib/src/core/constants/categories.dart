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
      key: '카페',
      label: '카페',
      icon: Icons.local_cafe,
      color: AppColors.chipCafe,
    ),
    SpendCategory(
      key: '교통',
      label: '교통',
      icon: Icons.directions_bus,
      color: AppColors.chipTransport,
    ),
    SpendCategory(
      key: '생활',
      label: '생활',
      icon: Icons.home,
      color: AppColors.chipLife,
    ),
    SpendCategory(
      key: '디지털구독',
      label: '디지털구독',
      icon: Icons.subscriptions,
      color: AppColors.chipSubscription,
    ),
    SpendCategory(
      key: '쇼핑',
      label: '쇼핑',
      icon: Icons.shopping_bag,
      color: AppColors.chipShopping,
    ),
    SpendCategory(
      key: '온라인쇼핑',
      label: '온라인쇼핑',
      icon: Icons.laptop,
      color: AppColors.chipOnline,
    ),
    SpendCategory(
      key: '편의점',
      label: '편의점',
      icon: Icons.store,
      color: AppColors.chipConvenience,
    ),
    SpendCategory(
      key: '마트',
      label: '마트',
      icon: Icons.shopping_cart,
      color: AppColors.chipMart,
    ),
    SpendCategory(
      key: '전통시장',
      label: '전통시장',
      icon: Icons.storefront,
      color: AppColors.chipTraditional,
    ),
    SpendCategory(
      key: '해외',
      label: '해외',
      icon: Icons.flight_takeoff,
      color: AppColors.chipOverseas,
    ),
    SpendCategory(
      key: '무이자할부',
      label: '무이자할부',
      icon: Icons.payment,
      color: AppColors.chipInstallment,
    ),
    SpendCategory(
      key: '주유',
      label: '주유',
      icon: Icons.local_gas_station,
      color: AppColors.chipGas,
    ),
    SpendCategory(
      key: '문화',
      label: '문화',
      icon: Icons.theater_comedy,
      color: AppColors.chipCulture,
    ),
    SpendCategory(
      key: '배달앱',
      label: '배달앱',
      icon: Icons.delivery_dining,
      color: AppColors.chipDelivery,
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
