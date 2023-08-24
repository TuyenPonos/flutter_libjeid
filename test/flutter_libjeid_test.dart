import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_libjeid/flutter_libjeid_platform_interface.dart';
import 'package:flutter_libjeid/flutter_libjeid_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterLibjeidPlatform
    with MockPlatformInterfaceMixin
    implements FlutterLibjeidPlatform {
  @override
  Future<Map<String, dynamic>> scanRCCard({required String cardNumber}) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> scanINCard({required String cardPin}) {
    throw UnimplementedError();
  }
}

void main() {
  final FlutterLibjeidPlatform initialPlatform =
      FlutterLibjeidPlatform.instance;

  test('$MethodChannelFlutterLibjeid is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterLibjeid>());
  });

  test('scanRCCard', () async {
    MockFlutterLibjeidPlatform fakePlatform = MockFlutterLibjeidPlatform();
    FlutterLibjeidPlatform.instance = fakePlatform;
  });
}
