import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  static double getWidth(BuildContext context, double mobileWidth, double tabletWidth, double desktopWidth) {
    if (isMobile(context)) {
      return mobileWidth;
    } else if (isTablet(context)) {
      return tabletWidth;
    } else {
      return desktopWidth;
    }
  }

  static double getPadding(BuildContext context, double mobilePadding, double tabletPadding, double desktopPadding) {
    if (isMobile(context)) {
      return mobilePadding;
    } else if (isTablet(context)) {
      return tabletPadding;
    } else {
      return desktopPadding;
    }
  }

  static int getCrossAxisCount(BuildContext context) {
    if (isMobile(context)) {
      return 2;
    } else if (isTablet(context)) {
      return 3;
    } else {
      return 4;
    }
  }
}
