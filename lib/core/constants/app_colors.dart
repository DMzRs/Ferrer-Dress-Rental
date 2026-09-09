import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color cream = Color(0xFFFDF8F2);
  static const Color creamDeep = Color(0xFFF6EDE1);
  static const Color blush = Color(0xFFF3CBD3);
  static const Color blushSoft = Color(0xFFFAEAEE);
  static const Color rose = Color(0xFFC4798B);
  static const Color roseDark = Color(0xFFA85D6F);
  static const Color gold = Color(0xFFC9A24B);
  static const Color goldSoft = Color(0xFFEBD7AE);
  static const Color champagne = Color(0xFFF2E6D4);
  static const Color ink = Color(0xFF40302B);
  static const Color inkSoft = Color(0xFF8D7A73);
  static const Color white = Colors.white;
  static const Color danger = Color(0xFFBF544E);
  static const Color success = Color(0xFF54876B);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFF0BFCB), Color(0xFFE6C89C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deeper brand tones for primary buttons — white text stays readable.
  static const LinearGradient brandGradientStrong = LinearGradient(
    colors: [Color(0xFFA85D6F), Color(0xFFC9A24B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient creamGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFBF6), Color(0xFFF7EDE0)],
  );

  static const List<List<Color>> itemPlaceholderGradients = [
    [Color(0xFFF6D7DC), Color(0xFFEDBCC7)],
    [Color(0xFFEFE2CB), Color(0xFFDFC79A)],
    [Color(0xFFEADCE4), Color(0xFFCFB4C6)],
    [Color(0xFFE3E7DC), Color(0xFFC2CDB4)],
    [Color(0xFFE8E0EF), Color(0xFFC6B8D8)],
  ];

  static const Color adminPrimary = Color(0xFF0D5C50);
  static const Color adminPrimaryDark = Color(0xFF093F37);
  static const Color adminPrimarySoft = Color(0xFFE2F0EC);
  static const Color adminSurface = Color(0xFFF4F7F6);
  static const Color adminCard = Color(0xFFFFFFFF);
  static const Color adminBorder = Color(0xFFE1E8E5);
  static const Color adminInk = Color(0xFF16262A);
  static const Color adminMuted = Color(0xFF65777C);
  static const Color adminAmber = Color(0xFFB27A22);
  static const Color adminViolet = Color(0xFF6B5CA5);
  static const Color adminRed = Color(0xFFAF3F30);
  static const Color adminBlue = Color(0xFF2F5D8A);
}
