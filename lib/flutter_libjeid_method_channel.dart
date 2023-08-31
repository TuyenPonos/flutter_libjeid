import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_libjeid_platform_interface.dart';

/// An implementation of [FlutterLibjeidPlatform] that uses method channels.
class MethodChannelFlutterLibjeid extends FlutterLibjeidPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_libjeid');

  @override
  Future<Map<String, dynamic>> scanRCCard({required String cardNumber}) async {
    final response = await methodChannel.invokeMethod(
      'scanRCCard',
      {
        'card_number': cardNumber,
      },
    );
    return Map.from(response);
  }

  @override
  Future<Map<String, dynamic>> scanINCard({required String cardPin}) async {
    final response = await methodChannel.invokeMethod(
      'scanINCard',
      {
        'pin': cardPin,
      },
    );
    return Map.from(response);
  }

  @override
  Future<Map<String, dynamic>> scanDLCard({
    required String cardPin1,
    required String cardPin2,
  }) async {
    final response = await methodChannel.invokeMethod(
      'scanDLCard',
      {
        'pin_1': cardPin1,
        'pin_2': cardPin2,
      },
    );
    return Map.from(response);
  }

  @override
  Future<void> stopScan() async {
    await methodChannel.invokeMethod('stopScan');
  }
}
