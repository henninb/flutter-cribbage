import 'dart:convert';

import 'package:flutter/services.dart';

class HumanSecurityService {
  static const _channel = MethodChannel('com.humansecurity/sdk');

  Future<Map<String, String>> getHeaders() async {
    final String? jsonString =
        await _channel.invokeMethod<String>('humanGetHeaders');
    if (jsonString == null) return {};
    final Map<String, dynamic> decoded =
        json.decode(jsonString) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  Future<String> handleBlockedResponse(String responseBody) async {
    final String result = await _channel.invokeMethod<String>(
          'humanHandleResponse',
          responseBody,
        ) ??
        'false';
    return result;
  }
}
