import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded, ultra }

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return ScreenSize.compact; // 360px: мобильный
  if (width < 1024) return ScreenSize.medium; // 768px: планшет
  if (width < 1440) return ScreenSize.expanded; // 1280px: десктоп
  return ScreenSize.ultra; // 1920px: ультра-широкий
}
