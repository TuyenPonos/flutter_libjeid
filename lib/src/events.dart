import 'package:flutter_libjeid/src/errors.dart';

import 'models.dart';

enum FlutterLibjeidEventType {
  scanning('scanning'),
  connecting('connecting'),
  parsing('parsing'),
  success('success'),
  failed('failed'),
  cancelled('cancelled');

  final String value;

  const FlutterLibjeidEventType(this.value);

  static FlutterLibjeidEventType? tryParse(String value) {
    return values
        .cast<FlutterLibjeidEventType?>()
        .firstWhere((e) => e?.value == value, orElse: () => null);
  }
}

abstract class FlutterLibjeidEvent {
  FlutterLibjeidEvent(this.type);

  final FlutterLibjeidEventType type;

  factory FlutterLibjeidEvent.parse(Map map) {
    final type = FlutterLibjeidEventType.tryParse(map['type']);

    switch (type) {
      case FlutterLibjeidEventType.scanning:
        return FlutterLibjeidEventScanning();

      case FlutterLibjeidEventType.connecting:
        return FlutterLibjeidEventConnecting();

      case FlutterLibjeidEventType.parsing:
        return FlutterLibjeidEventParsing();

      case FlutterLibjeidEventType.success:
        return FlutterLibjeidEventSuccess(FlutterLibjeidCardData.fromJSON(map['data']));

      case FlutterLibjeidEventType.failed:
        return FlutterLibjeidEventFailed(FlutterLibjeidError.fromJSON(map['data']));

      case FlutterLibjeidEventType.cancelled:
        return FlutterLibjeidEventCancelled();

      default:
        throw Exception('Invalid event type: ${map['type']}');
    }
  }
}

/// Event that will be emitted when the device's NFC reader is start scanning for NFC card
class FlutterLibjeidEventScanning extends FlutterLibjeidEvent {
  FlutterLibjeidEventScanning() : super(FlutterLibjeidEventType.scanning);
}

/// Event that will be emitted when the device's NFC reader is connecting to the NFC card
class FlutterLibjeidEventConnecting extends FlutterLibjeidEvent {
  FlutterLibjeidEventConnecting() : super(FlutterLibjeidEventType.connecting);
}

/// Event that will be emitted when the device's NFC reader is parsing the NFC card data
class FlutterLibjeidEventParsing extends FlutterLibjeidEvent {
  FlutterLibjeidEventParsing() : super(FlutterLibjeidEventType.parsing);
}

/// Event that will be emitted when the device's NFC reader is successfully read the NFC card data
class FlutterLibjeidEventSuccess extends FlutterLibjeidEvent {
  FlutterLibjeidEventSuccess(this.data) : super(FlutterLibjeidEventType.success);

  final FlutterLibjeidCardData data;
}

/// Event that will be emitted when the device's NFC reader is failed to connect or read the NFC card data
class FlutterLibjeidEventFailed extends FlutterLibjeidEvent {
  FlutterLibjeidEventFailed(this.error) : super(FlutterLibjeidEventType.failed);

  final FlutterLibjeidError error;
}

/// Event that will be emitted when the device's NFC reader is cancelled by calling the "stopScan" method
class FlutterLibjeidEventCancelled extends FlutterLibjeidEvent {
  FlutterLibjeidEventCancelled() : super(FlutterLibjeidEventType.cancelled);
}
