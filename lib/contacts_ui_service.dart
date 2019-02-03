import 'dart:async';

import 'package:flutter/services.dart';

class ContactsUiService {
  static const MethodChannel _channel =
      const MethodChannel('contacts_ui_service');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
