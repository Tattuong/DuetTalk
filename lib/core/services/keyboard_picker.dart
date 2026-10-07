import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/app_toast.dart';

class KeyboardPicker {
  KeyboardPicker._();

  static const _channel = MethodChannel('duettalk/keyboard');

  static Future<void> show(BuildContext context) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod<bool>('showPicker');
        return;
      } catch (error) {
        debugPrint('Keyboard picker failed: $error');
      }
    }
    if (!context.mounted) return;
    AppToast.show(context, title: 'Hold the globe key to change the keyboard');
  }
}
