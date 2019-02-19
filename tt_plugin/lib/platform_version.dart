import 'dart:async';
import 'package:flutter/services.dart';

// a code from template. Not used currently

class TTPlugin {
    static const MethodChannel _channel = const MethodChannel('tt_plugin');

    static Future<String> get platformVersion async {
        final String version = await _channel.invokeMethod('getPlatformVersion');
        return version;
    }
}
