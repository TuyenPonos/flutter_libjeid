import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_libjeid/flutter_libjeid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  Map<String, dynamic> _data = {};
  String? _error;
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey();

  final _flutterLibjeidPlugin = FlutterLibjeid();
  final TextEditingController _rcCardNumberController = TextEditingController();
  final TextEditingController _inCardPinController = TextEditingController();
  final TextEditingController _dlCardPin1Controller = TextEditingController();
  final TextEditingController _dlCardPin2Controller = TextEditingController();
  final TextEditingController _epCardNumberController = TextEditingController();
  final TextEditingController _epCardBirthDateController =
      TextEditingController();
  final TextEditingController _epCardExpiredDateController =
      TextEditingController();

  late final TabController _tabController;
  late final StreamSubscription<FlutterLibjeidEvent> _eventStreamSubscription;

  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this);
    _eventStreamSubscription =
        _flutterLibjeidPlugin.eventStream.listen(_onEventReceived);

    scheduleMicrotask(() {
      _flutterLibjeidPlugin.isAvailable().then((isAvailable) {
        if (!isAvailable) {
          setState(() => _error = 'NFC Not Available');
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _eventStreamSubscription.cancel();
    super.dispose();
  }

  void _onEventReceived(FlutterLibjeidEvent event) {
    switch (event) {
      case FlutterLibjeidEventScanning():
        _flutterLibjeidPlugin.setMessage(message: 'Scanning...');
        setState(() {
          _data = Map.from({});
          _error = null;
        });
        break;

      case FlutterLibjeidEventConnecting():
        _flutterLibjeidPlugin.setMessage(message: 'Connecting...');
        break;

      case FlutterLibjeidEventParsing():
        _flutterLibjeidPlugin.setMessage(message: 'Parsing...');
        break;

      case FlutterLibjeidEventSuccess(data: FlutterLibjeidCardData data):
        _flutterLibjeidPlugin.stopScan();

        _data = data.toJson();

        FocusScope.of(context).unfocus();

        _globalKey.currentState?.showBottomSheet(
          (_) => BottomSheet(
            onClosing: () {},
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            builder: (_) => SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _data.entries
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(e.key)),
                            Expanded(
                              flex: 3,
                              child: Builder(builder: (context) {
                                final value = e.value;
                                if (value is String &&
                                    value.startsWith('data:image/')) {
                                  return Image.memory(
                                    const Base64Decoder().convert(
                                      value.replaceFirst(
                                          'data:image/png;base64,', ''),
                                    ),
                                  );
                                }
                                return Text(e.value.toString());
                              }),
                            )
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );

        setState(() {});
        break;

      case FlutterLibjeidEventFailed(error: FlutterLibjeidError error):
        _flutterLibjeidPlugin.stopScan();
        setState(() => _error = error.toString());
        break;

      case FlutterLibjeidEventCancelled():
        break;
    }
  }

  Future<void> startScanResidentCard() async {
    try {
      await _flutterLibjeidPlugin.scanResidentCard(
        cardNumber: _rcCardNumberController.text,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> scanMyNumberCard() async {
    try {
      await _flutterLibjeidPlugin.scanMyNumberCard(
        pin: _inCardPinController.text,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> startScanDriverLicenseCard() async {
    try {
      await _flutterLibjeidPlugin.scanDriverLicenseCard(
        pin1: _dlCardPin1Controller.text,
        pin2: _dlCardPin2Controller.text,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> startScanPassportCard() async {
    try {
      await _flutterLibjeidPlugin.scanPassportCard(
        cardNumber: _epCardNumberController.text,
        birthDate: _epCardBirthDateController.text,
        expiredDate: _epCardExpiredDateController.text,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          key: _globalKey,
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            title: const Text('Libjeid Example'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'The plugin is under development, it can cause crash app. KEEP CALM ^_^',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelStyle: const TextStyle(fontSize: 16),
                  labelColor: Colors.blue,
                  isScrollable: true,
                  tabs: const [
                    SizedBox(height: 30, child: Text('My number (IN)')),
                    SizedBox(height: 30, child: Text('Driver License (DL)')),
                    SizedBox(height: 30, child: Text('Residence (RC)')),
                    SizedBox(height: 30, child: Text('Passport (EP)')),
                  ],
                  onTap: (index) {
                    setState(() {
                      _data = Map.from({});
                      _error = null;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Column(
                        children: [
                          TextFormField(
                            controller: _inCardPinController,
                            maxLength: 4,
                            decoration: const InputDecoration(
                              hintText: 'Input PIN',
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: scanMyNumberCard,
                            child: const Text('Scan My Number Card'),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _dlCardPin1Controller,
                                  maxLength: 4,
                                  decoration: const InputDecoration(
                                    hintText: 'Input PIN 1',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _dlCardPin2Controller,
                                  maxLength: 4,
                                  decoration: const InputDecoration(
                                    hintText: 'Input PIN 2',
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: startScanDriverLicenseCard,
                            child: const Text('Scan Driver License Card'),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          TextFormField(
                            maxLength: 12,
                            controller: _rcCardNumberController,
                            decoration: const InputDecoration(
                              hintText: 'Input card number',
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: startScanResidentCard,
                            child: const Text('Scan Residence Card'),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          TextFormField(
                            maxLength: 12,
                            controller: _epCardNumberController,
                            decoration: const InputDecoration(
                              hintText: 'Input card number',
                            ),
                          ),
                          TextFormField(
                            maxLength: 12,
                            controller: _epCardBirthDateController,
                            decoration: const InputDecoration(
                              hintText: 'Input birth date (YYMMDD)',
                            ),
                          ),
                          TextFormField(
                            maxLength: 12,
                            controller: _epCardExpiredDateController,
                            decoration: const InputDecoration(
                              hintText: 'Input expired date (YYMMDD)',
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: startScanResidentCard,
                            child: const Text('Scan Residence Card'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_error?.isNotEmpty ?? false)
                  Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _data.entries
                          .map(
                            (e) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(e.key)),
                                  Expanded(
                                    flex: 3,
                                    child: Builder(builder: (context) {
                                      final value = e.value;
                                      if (value is String &&
                                          value.startsWith('data:image/')) {
                                        return Image.memory(
                                          const Base64Decoder().convert(
                                            value.replaceFirst(
                                                'data:image/png;base64,', ''),
                                          ),
                                        );
                                      }
                                      return Text(e.value.toString());
                                    }),
                                  )
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
