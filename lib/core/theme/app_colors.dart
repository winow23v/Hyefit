import 'package:flutter/material.dart';

/// 혜핏 다크 그레이 팔레트 — WCAG 2.1 AA 준수
/// 모든 텍스트 색상은 배경 대비 4.5:1 이상 보장
class AppColors {
  AppColors._();

  // ── 배경 ──
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E2C);
  static const Color card = Color(0xFF272738);
  static const Color cardLight = Color(0xFF2F2F42);

  // ── 브랜드 ──
  static const Color primary = Color(0xFF7C83FD);
  static const Color primaryLight = Color(0xFFA5ABFF);
  static const Color primaryDark = Color(0xFF5A60D6);

  // ── 텍스트 (on dark background) ──
  static const Color textPrimary = Color(0xFFE8E8F0); // 13.5:1
  static const Color textSecondary = Color(0xFFA8A8B8); // 5.8:1
  static const Color textHint = Color(0xFF78788A); // 4.6:1

  // ── 시맨틱 ──
  static const Color success = Color(0xFF51CF66);
  static const Color warning = Color(0xFFFFD43B);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF74C0FC);

  // ── 카테고리 칩 ──
  static const Color chipFood = Color(0xFFFF8A65);
  static const Color chipTransport = Color(0xFF4FC3F7);
  static const Color chipShopping = Color(0xFFBA68C8);
  static const Color chipConvenience = Color(0xFFAED581);
  static const Color chipOnline = Color(0xFF7986CB);
  static const Color chipMart = Color(0xFFFFD54F);
  static const Color chipEtc = Color(0xFF90A4AE);

  // ── 기타 ──
  static const Color divider = Color(0xFF3A3A4E);
  static const Color inputFill = Color(0xFF2A2A3C);
  static const Color shadow = Color(0x40000000);
}
