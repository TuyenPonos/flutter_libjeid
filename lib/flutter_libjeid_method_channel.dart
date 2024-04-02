import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/events.dart';
import 'flutter_libjeid_platform_interface.dart';

/// An implementation of [FlutterLibjeidPlatform] that uses method channels.
class MethodChannelFlutterLibjeid extends FlutterLibjeidPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_libjeid');

  @visibleForTesting
  final eventChannel = const EventChannel('flutter_libjeid_card_data_event');

  Stream<FlutterLibjeidEvent>? _eventStream;

  @override
  Future<bool> isAvailable() async {
    final isAvailable = await methodChannel.invokeMethod<bool>('isAvailable');
    return isAvailable ?? false;
  }

  @override
  Future<void> setMessage({
    required String message,
  }) {
    return methodChannel.invokeMethod('setMessage', {
      'message': message,
    });
  }

  @override
  Future<void> scanResidentCard({
    required String cardNumber,
  }) {
    return methodChannel.invokeMethod('scanResidentCard', {
      'card_number': cardNumber,
    });
  }

  @override
  Future<void> scanMyNumberCard({
    required String pin,
  }) {
    return methodChannel.invokeMethod('scanMyNumberCard', {
      'pin': pin,
    });
  }

  @override
  Future<void> scanDriverLicenseCard({
    required String pin1,
    required String pin2,
  }) {
    return methodChannel.invokeMethod('scanDriverLicenseCard', {
      'pin_1': pin1,
      'pin_2': pin2,
    });
  }

  @override
  Future<void> scanPassportCard({
    required String cardNumber,
    required String birthDate,
    required String expiredDate,
  }) {
    return methodChannel.invokeMethod('scanPassportCard', {
      'card_number': cardNumber,
      'birth_date': birthDate,
      'expired_date': expiredDate,
    });
  }

  @override
  Future<void> stopScan() {
    return methodChannel.invokeMethod('stopScan');
  }

  @override
  Stream<FlutterLibjeidEvent> get eventStream {
    _eventStream ??= eventChannel
        .receiveBroadcastStream()
        .map((event) => Map.from(event))
        .map(FlutterLibjeidEvent.parse);

    return _eventStream!;
  }
}
