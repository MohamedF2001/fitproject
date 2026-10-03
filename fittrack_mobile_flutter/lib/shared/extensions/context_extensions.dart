import 'package:flutter/widgets.dart';

extension ContextSize on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isCompact => screenWidth < 360;
}
