
import 'dart:async';

import 'package:flutter/services.dart';

class FlutterWebGl {
  static const MethodChannel _channel =
      const MethodChannel('flutter_web_gl');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
