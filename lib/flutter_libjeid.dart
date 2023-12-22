import 'src/events.dart';
import 'flutter_libjeid_platform_interface.dart';

export 'src/events.dart';
export 'src/models.dart';
export 'src/errors.dart';

class FlutterLibjeid {
  /// Check whether the NFC reader is available on the device
  Future<bool> isAvailable() {
    return FlutterLibjeidPlatform.instance.isAvailable();
  }

  /// Set the message that will be displayed on the NFC reader dialog
  Future<void> setMessage({
    required String message,
  }) {
    return FlutterLibjeidPlatform.instance.setMessage(message: message);
  }

  /// Start the Resident (RC) Card scanning process
  /// The [cardNumber] value is required to read the content of the card
  Future<void> scanResidentCard({
    required String cardNumber,
  }) {
    return FlutterLibjeidPlatform.instance.scanResidentCard(cardNumber: cardNumber);
  }

  /// Start the My Number (IN) Card scanning process
  /// The [pin] is required to read the content of the card
  Future<void> scanMyNumberCard({
    required String pin,
  }) {
    return FlutterLibjeidPlatform.instance.scanMyNumberCard(pin: pin);
  }

  /// Start the Driver License (DL) Card scanning process
  /// The [pin1] and [pin2] is required to read the content of the card
  Future<void> scanDriverLicenseCard({
    required String pin1,
    required String pin2,
  }) async {
    return FlutterLibjeidPlatform.instance.scanDriverLicenseCard(pin1: pin1, pin2: pin2);
  }

  /// Start the Passport (EP) Card scanning progress
  /// The [cardNumber], [birthDate], and [expiredDate] is required to read the content of the card
  Future<void> scanPassportCard({
    required String cardNumber,
    required String birthDate,
    required String expiredDate,
  }) async {
    return FlutterLibjeidPlatform.instance.scanPassportCard(
      cardNumber: cardNumber,
      birthDate: birthDate,
      expiredDate: expiredDate,
    );
  }

  /// Stop the current scanning progress
  /// Will do nothing if there is no scanning progress
  Future<void> stopScan() {
    return FlutterLibjeidPlatform.instance.stopScan();
  }

  /// Get the event stream of the NFC reader
  /// The event stream will emit [FlutterLibjeidEvent] when the NFC reader state is changed
  Stream<FlutterLibjeidEvent> get eventStream {
    return FlutterLibjeidPlatform.instance.eventStream;
  }
}
