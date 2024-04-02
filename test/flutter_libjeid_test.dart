import 'package:flutter_libjeid/flutter_libjeid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_libjeid/flutter_libjeid_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  late FlutterLibjeid flutterLibjeid;
  MockFlutterLibjeidPlatform fakePlatform = MockFlutterLibjeidPlatform();

  group('$FlutterLibjeid', () {
    setUp(() {
      fakePlatform = MockFlutterLibjeidPlatform();
      FlutterLibjeidPlatform.instance = fakePlatform;
      flutterLibjeid = FlutterLibjeid();

      expect(fakePlatform.calledMethod, null);
      expect(fakePlatform.callArgs, null);
    });

    test('isAvailable', () async {
      final result = await flutterLibjeid.isAvailable();

      expect(fakePlatform.calledMethod, 'isAvailable');
      expect(result, true);
    });

    test('setMessage', () async {
      const mockMessage = 'some test message';

      await flutterLibjeid.setMessage(message: mockMessage);

      expect(fakePlatform.calledMethod, 'setMessage');
      expect(fakePlatform.callArgs, {'message': mockMessage});
    });

    test('scanResidentCard', () async {
      const mockCardNumber = '1234567890';

      await flutterLibjeid.scanResidentCard(cardNumber: mockCardNumber);

      expect(fakePlatform.calledMethod, 'scanResidentCard');
      expect(fakePlatform.callArgs, {'cardNumber': mockCardNumber});
    });

    test('scanMyNumberCard', () async {
      const mockPin = '1234';

      await flutterLibjeid.scanMyNumberCard(pin: mockPin);

      expect(fakePlatform.calledMethod, 'scanMyNumberCard');
      expect(fakePlatform.callArgs, {'pin': mockPin});
    });

    test('stopScan', () async {
      await flutterLibjeid.stopScan();

      expect(fakePlatform.calledMethod, 'stopScan');
      expect(fakePlatform.callArgs, null);
    });

    test('scanDriverLicenseCard', () async {
      const mockPin1 = '1234';
      const mockPin2 = '5678';

      await flutterLibjeid.scanDriverLicenseCard(pin1: mockPin1, pin2: mockPin2);

      expect(fakePlatform.calledMethod, 'scanDriverLicenseCard');
      expect(fakePlatform.callArgs, {'pin1': mockPin1, 'pin2': mockPin2});
    });

    test('scanPassportCard', () async {
      const mockCardNumber = '123456789';
      const mockBirthDate = '231222';
      const mockExpiredDate = '271222';

      await flutterLibjeid.scanPassportCard(
        cardNumber: mockCardNumber,
        birthDate: mockBirthDate,
        expiredDate: mockExpiredDate,
      );

      expect(fakePlatform.calledMethod, 'scanPassportCard');
      expect(fakePlatform.callArgs, {
        'cardNumber': mockCardNumber,
        'birthDate': mockBirthDate,
        'expiredDate': mockExpiredDate,
      });
    });

    test('eventStream', () async {
      final events = <FlutterLibjeidEvent>[];
      final stream = flutterLibjeid.eventStream.asBroadcastStream();
      final subscription = stream.listen(events.add);

      await stream.lastWhere((event) => event is FlutterLibjeidEventFailed);

      expect(events.length, 4);
      expect(events[0], isA<FlutterLibjeidEventScanning>());
      expect(events[1], isA<FlutterLibjeidEventConnecting>());
      expect(events[2], isA<FlutterLibjeidEventParsing>());
      expect(events[3], isA<FlutterLibjeidEventFailed>());
      expect((events[3] as FlutterLibjeidEventFailed).error.details, {'message': 'test'});

      await subscription.cancel();
    });
  });
}

class MockFlutterLibjeidPlatform with MockPlatformInterfaceMixin implements FlutterLibjeidPlatform {
  String? calledMethod;
  Map<String, dynamic>? callArgs;

  @override
  Future<bool> isAvailable() async {
    calledMethod = 'isAvailable';
    return true;
  }

  @override
  Future<void> setMessage({required String message}) {
    calledMethod = 'setMessage';
    callArgs = {'message': message};
    return Future.value();
  }

  @override
  Future<void> scanResidentCard({required String cardNumber}) async {
    calledMethod = 'scanResidentCard';
    callArgs = {'cardNumber': cardNumber};
  }

  @override
  Future<void> scanMyNumberCard({required String pin}) async {
    calledMethod = 'scanMyNumberCard';
    callArgs = {'pin': pin};
  }

  @override
  Future<void> stopScan() async {
    calledMethod = 'stopScan';
    callArgs = null;
  }

  @override
  Future<void> scanDriverLicenseCard({required String pin1, required String pin2}) async {
    calledMethod = 'scanDriverLicenseCard';
    callArgs = {'pin1': pin1, 'pin2': pin2};
  }

  @override
  Future<void> scanPassportCard(
      {required String cardNumber, required String birthDate, required String expiredDate}) async {
    calledMethod = 'scanPassportCard';
    callArgs = {'cardNumber': cardNumber, 'birthDate': birthDate, 'expiredDate': expiredDate};
  }

  @override
  Stream<FlutterLibjeidEvent> get eventStream async* {
    yield FlutterLibjeidEventScanning();
    yield FlutterLibjeidEventConnecting();
    yield FlutterLibjeidEventParsing();
    yield FlutterLibjeidEventFailed(UnknownError({'message': 'test'}));
  }
}
