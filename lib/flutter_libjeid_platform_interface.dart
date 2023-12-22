import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/events.dart';
import 'flutter_libjeid_method_channel.dart';

abstract class FlutterLibjeidPlatform extends PlatformInterface {
  /// Constructs a FlutterLibjeidPlatform.
  FlutterLibjeidPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterLibjeidPlatform _instance = MethodChannelFlutterLibjeid();

  /// The default instance of [FlutterLibjeidPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterLibjeid].
  static FlutterLibjeidPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterLibjeidPlatform] when
  /// they register themselves.
  static set instance(FlutterLibjeidPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Check whether the NFC reader is available on the device
  Future<bool> isAvailable() {
    throw UnimplementedError('isAvailable() has not been implemented.');
  }

  /// Set the message that will be displayed on the NFC reader dialog
  Future<void> setMessage({
    required String message,
  }) {
    throw UnimplementedError('setMessage() has not been implemented.');
  }

  /// Start the Resident (RC) Card scanning process
  /// The [cardNumber] value is required to read the content of the card
  Future<void> scanResidentCard({
    required String cardNumber,
  }) {
    throw UnimplementedError('scanResidentCard() has not been implemented.');
  }

  /// Start the My Number (IN) Card scanning process
  /// The [pin] is required to read the content of the card
  Future<void> scanMyNumberCard({
    required String pin,
  }) {
    throw UnimplementedError('scanMyNumberCard() has not been implemented.');
  }

  /// Start the Driver License (DL) Card scanning process
  /// The [pin1] and [pin2] is required to read the content of the card
  Future<void> scanDriverLicenseCard({
    required String pin1,
    required String pin2,
  }) async {
    throw UnimplementedError('scanDriverLicenseCard() has not been implemented.');
  }

  /// Start the Passport (EP) Card scanning progress
  /// The [cardNumber], [birthDate], and [expiredDate] is required to read the content of the card
  Future<void> scanPassportCard({
    required String cardNumber,
    required String birthDate,
    required String expiredDate,
  }) async {
    throw UnimplementedError('scanPassportCard() has not been implemented.');
  }

  /// Stop the current scanning progress
  /// Will do nothing if there is no scanning progress
  Future<void> stopScan() {
    throw UnimplementedError('stopScan() has not been implemented.');
  }

  Stream<FlutterLibjeidEvent> get eventStream {
    throw UnimplementedError('get onConnectivityChanged has not been implemented.');
  }
}
