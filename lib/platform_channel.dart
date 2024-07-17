import 'package:flutter/services.dart';

class PlatformChannel {
  static const _channel = MethodChannel("sms.receiver.channel");

  Future<Map<String, String>> receiveSms() async {
    try {
      final result = await _channel.invokeMethod("receive_sms");
      return Map<String, String>.from(result);
    } catch (e) {
      return {
        'sender': 'Failed to receive SMS',
        'message': e.toString(),
      };
    }
  }
}
