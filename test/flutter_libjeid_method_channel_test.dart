import 'package:flutter/services.dart';
import 'package:flutter_libjeid/flutter_libjeid_method_channel.dart';
import 'package:flutter_libjeid/src/events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("$MethodChannelFlutterLibjeid", () {
    late MethodChannelFlutterLibjeid methodChannelFlutterLibjeid;

    setUp(() {
      methodChannelFlutterLibjeid = MethodChannelFlutterLibjeid();
    });

    test('isAvailable', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannelFlutterLibjeid.methodChannel,
        (call) async {
          expect(call.method, 'isAvailable');
          return true;
        },
      );

      final result = await methodChannelFlutterLibjeid.isAvailable();
      expect(result, true);
    });

    test('setMessage', () async {
      const mockMessage = 'some test message';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannelFlutterLibjeid.methodChannel,
        (call) async {
          expect(call.method, 'setMessage');
          expect(call.arguments['message'], mockMessage);
          return null;
        },
      );

      await methodChannelFlutterLibjeid.setMessage(message: mockMessage);
    });

    test('scanResidentCard', () async {
      const mockCardNumber = '1234567890';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannelFlutterLibjeid.methodChannel,
        (call) async {
          expect(call.method, 'scanResidentCard');
          expect(call.arguments['card_number'], mockCardNumber);
          return null;
        },
      );

      await methodChannelFlutterLibjeid.scanResidentCard(cardNumber: mockCardNumber);
    });

    test('scanMyNumberCard', () async {
      const mockPin = '1234';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannelFlutterLibjeid.methodChannel,
        (call) async {
          expect(call.method, 'scanMyNumberCard');
          expect(call.arguments['pin'], mockPin);
          return null;
        },
      );

      await methodChannelFlutterLibjeid.scanMyNumberCard(pin: mockPin);
    });

    test('scanDriverLicenseCard', () async {
      const mockPin1 = '1234';
      const mockPin2 = '5678';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannelFlutterLibjeid.methodChannel,
        (call) async {
          expect(call.method, 'scanDriverLicenseCard');
          expect(call.arguments['pin1'], mockPin1);
          expect(call.arguments['pin2'], mockPin2);
          return null;
        },
      );

      await methodChannelFlutterLibjeid.scanDriverLicenseCard(pin1: mockPin1, pin2: mockPin2);
    });

    test('scanPassportCard', () async {
      const mockCardNumber = '1234567890';
      const mockBirthDate = '231222';
      const mockExpiredDate = '271222';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannelFlutterLibjeid.methodChannel,
        (call) async {
          expect(call.method, 'scanPassportCard');
          expect(call.arguments['card_number'], mockCardNumber);
          expect(call.arguments['birth_date'], mockBirthDate);
          expect(call.arguments['expired_date'], mockExpiredDate);
          return null;
        },
      );

      await methodChannelFlutterLibjeid.scanPassportCard(
        cardNumber: mockCardNumber,
        birthDate: mockBirthDate,
        expiredDate: mockExpiredDate,
      );
    });

    test('stopScan', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannelFlutterLibjeid.methodChannel,
        (call) async {
          expect(call.method, 'stopScan');
          return null;
        },
      );

      await methodChannelFlutterLibjeid.stopScan();
    });

    test('eventStream', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel(methodChannelFlutterLibjeid.eventChannel.name),
        (call) async {
          switch (call.method) {
            case 'listen':
              await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                  .handlePlatformMessage(
                methodChannelFlutterLibjeid.eventChannel.name,
                methodChannelFlutterLibjeid.eventChannel.codec
                    .encodeSuccessEnvelope({'type': 'scanning'}),
                (_) {},
              );
              break;

            case 'cancel':
          }
          return null;
        },
      );

      final result = await methodChannelFlutterLibjeid.eventStream.first;
      expect(result, isA<FlutterLibjeidEventScanning>());
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannelFlutterLibjeid.methodChannel, null);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel(methodChannelFlutterLibjeid.eventChannel.name), null);
    });
  });
}
