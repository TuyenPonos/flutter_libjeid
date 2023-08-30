import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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

  /// Scan RC Card
  /// Input [cardNumber] ex: 123456789123
  /// Return {} when cancelled

  Future<Map<String, dynamic>> scanRCCard({
    required String cardNumber,
  }) {
    return _instance.scanRCCard(cardNumber: cardNumber);
  }

  /// Scan IN Card
  /// Input [cardPin] ex: 1234
  /// Return {} when cancelled
  Future<Map<String, dynamic>> scanINCard({
    required String cardPin,
  }) {
    return _instance.scanINCard(cardPin: cardPin);
  }

  /// Stop all card scanning
  Future<void> stopScan() {
    return _instance.stopScan();
  }
}
