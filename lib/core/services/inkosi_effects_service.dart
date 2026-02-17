import 'dart:math';

import 'package:flutter/widgets.dart';

class InkosiEffectsService {
  bool shouldRenderEffect({required bool reduceMotion, required bool userEnabled}) {
    if (reduceMotion) return false;
    if (!userEnabled) return false;
    return Random().nextDouble() < 0.3;
  }
}
