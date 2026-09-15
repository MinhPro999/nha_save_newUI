import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = lightLinearShape;
  static const secondary = lightButtonStart;
  static const lightLinearShape = Color(0xFFFE5196);
  static const darkLinearShape = Color(0xFFD09693);
  static const lightButtonStart = Color(0xFFF77062);
  static const darkButtonStart = Color(0xFFC71D6F);
  static const lightNavigationStart = Color(0xFFFDFCFB);
  static const lightNavigationEnd = Color(0xFFE2D1C3);
  static const darkNavigationStart = Color(0xFF29323C);
  static const darkNavigationEnd = Color(0xFF485563);
  static const lightBackground = Color(0xFFF9F8FC);
  static const darkBackground = Color(0xFF121119);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF211F2A);
  static const lightText = Color(0xFF15152A);
  static const darkText = Color(0xFFF5F3FF);
  static const muted = Color(0xFF8F91A3);
  static const lightGrey = Color(0xFFD5D4DE);
  static const darkGrey = Color(0xFF696777);

  static Color linearShapeForBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? darkLinearShape : lightLinearShape;
  }

  static Color linearShapeFor(BuildContext context) {
    return linearShapeForBrightness(Theme.of(context).brightness);
  }

  static Color buttonStartForBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? darkButtonStart : lightButtonStart;
  }

  static LinearGradient buttonGradientForBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [darkButtonStart, darkLinearShape],
          )
        : const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [lightButtonStart, lightLinearShape],
          );
  }

  static LinearGradient buttonGradientFor(BuildContext context) {
    return buttonGradientForBrightness(Theme.of(context).brightness);
  }

  static LinearGradient navigationGradientForBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkNavigationStart, darkNavigationEnd],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lightNavigationStart, lightNavigationEnd],
          );
  }

  static LinearGradient navigationGradientFor(BuildContext context) {
    return navigationGradientForBrightness(Theme.of(context).brightness);
  }

  static LinearGradient settingRowGradientFor(BuildContext context) {
    return navigationGradientFor(context);
  }
}
