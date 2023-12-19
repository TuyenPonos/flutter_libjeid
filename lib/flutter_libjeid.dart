import 'flutter_libjeid_platform_interface.dart';

class FlutterLibjeid {
  /// Scan RC Card
  /// Input [cardNumber] ex: 123456789123
  /// Return {} when cancelled
  Future<Map<String, dynamic>> scanRCCard({required String cardNumber}) {
    return FlutterLibjeidPlatform.instance.scanRCCard(cardNumber: cardNumber);
  }

  /// Scan IN Card
  /// Input [cardPin] ex: 1234
  /// Return {} when cancelled
  Future<Map<String, dynamic>> scanINCard({required String cardPin}) {
    return FlutterLibjeidPlatform.instance.scanINCard(cardPin: cardPin);
  }

  /// Scan DL Card
  /// Input [cardPin1] ex: 1234
  /// Input [cardPin2] ex: 1234
  /// Return {} when cancelled
  Future<Map<String, dynamic>> scanDLCard({
    required String cardPin1,
    required String cardPin2,
  }) {
    return FlutterLibjeidPlatform.instance.scanDLCard(
      cardPin1: cardPin1,
      cardPin2: cardPin2,
    );
  }

  /// Scan the EP (Passport) Card
  /// Input [cardNumber] ex: 123456789123
  /// Input [birthDate] (in YYMMDD format), for example: 231219
  /// Input [expiredDate] (in YYMMDD format), for example: 231219
  /// Return {} when cancelled
  Future<Map<String, dynamic>> scanEPCard({
    required String cardNumber,
    required String birthDate,
    required String expiredDate,
  }) {
    return FlutterLibjeidPlatform.instance.scanEPCard(
      cardNumber: cardNumber,
      birthDate: birthDate,
      expiredDate: expiredDate,
    );
  }

  Future<void> stopScan() async {
    return FlutterLibjeidPlatform.instance.stopScan();
  }
}
