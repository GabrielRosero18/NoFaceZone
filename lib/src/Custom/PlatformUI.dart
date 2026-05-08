import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformUI {
  static bool isWebDesktop(BuildContext context) {
    if (!kIsWeb) return false;
    final media = MediaQuery.maybeOf(context);
    if (media == null) return false;
    return media.size.width >= 1024;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    if (isWebDesktop(context)) {
      return const EdgeInsets.fromLTRB(36, 28, 36, 24);
    }
    return const EdgeInsets.fromLTRB(24, 18, 24, 16);
  }

  static Widget centeredContent({
    required BuildContext context,
    required Widget child,
    double maxWidth = 1160,
  }) {
    if (!isWebDesktop(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  static MouseCursor clickCursor = SystemMouseCursors.click;
}

class WebMotionTokens {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 180);
  static const Duration route = Duration(milliseconds: 460);

  static const double hoverLiftSoft = 3.0;
  static const double hoverLiftMedium = 4.0;
  static const double hoverScaleSoft = 1.004;
  static const double hoverScaleMedium = 1.008;

  static const List<BoxShadow> hoverShadowSoft = [
    BoxShadow(
      color: Color(0x24000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> hoverShadowMedium = [
    BoxShadow(
      color: Color(0x2D000000),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];
}
