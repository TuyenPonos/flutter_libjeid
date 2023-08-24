import 'package:flutter/services.dart';

import 'flutter_libjeid_platform_interface.dart';

class FlutterLibjeid {
  Future<Map<String, dynamic>> scanRCCard({required String cardNumber}) {
    if (cardNumber.isEmpty) {
      throw PlatformException(
        code: 'not_input_card_number',
        message: 'Please input a valid card number',
      );
    }
    return FlutterLibjeidPlatform.instance.scanRCCard(cardNumber: cardNumber);
  }

  Future<Map<String, dynamic>> scanINCard({required String cardPin}) {
    if (cardPin.length != 4) {
      throw PlatformException(
        code: 'not_input_card_pin',
        message: 'Please input a valid card pin',
      );
    }
    return FlutterLibjeidPlatform.instance.scanINCard(cardPin: cardPin);
  }
}