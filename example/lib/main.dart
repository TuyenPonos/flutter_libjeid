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
  final _flutterLibjeidPlugin = FlutterLibjeid();
  final TextEditingController _rcCardNumberController = TextEditingController();
  final TextEditingController _inCardPinController = TextEditingController();
  final TextEditingController _dlCardPin1Controller = TextEditingController();
  final TextEditingController _dlCardPin2Controller = TextEditingController();

  late final TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  Future<void> startScanRCCard() async {
    try {
      if (!mounted) {
        return;
      }
      setState(() {
        _data = Map.from({});
        _error = null;
      });
      final resp = await _flutterLibjeidPlugin.scanRCCard(
        cardNumber: _rcCardNumberController.text,
      );
      if (mounted && resp.isNotEmpty) {
        setState(() {
          _data = Map.from(resp);
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Code: "${e.code}": ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      _flutterLibjeidPlugin.stopScan();
    }
  }

  Future<void> startScanINCard() async {
    try {
      if (!mounted) {
        return;
      }
      setState(() {
        _data = Map.from({});
        _error = null;
      });
      final resp = await _flutterLibjeidPlugin.scanINCard(
        cardPin: _inCardPinController.text,
      );
      if (mounted && resp.isNotEmpty) {
        setState(() {
          _data = Map.from(resp);
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _error = '${e.code}: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      _flutterLibjeidPlugin.stopScan();
    }
  }

  Future<void> startScanDLCard() async {
    try {
      if (!mounted) {
        return;
      }
      setState(() {
        _data = Map.from({});
        _error = null;
      });
      final resp = await _flutterLibjeidPlugin.scanDLCard(
        cardPin1: _dlCardPin1Controller.text,
        cardPin2: _dlCardPin2Controller.text,
      );
      if (mounted && resp.isNotEmpty) {
        setState(() {
          _data = Map.from(resp);
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _error = '${e.code}: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      _flutterLibjeidPlugin.stopScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                  SizedBox(height: 30, child: Text('My number')),
                  SizedBox(height: 30, child: Text('Driver License')),
                  SizedBox(height: 30, child: Text('Residence')),
                ],
                onTap: (index) {
                  setState(() {
                    _data = Map.from({});
                    _error = null;
                  });
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 130,
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
                          onPressed: startScanINCard,
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
                          onPressed: startScanDLCard,
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
                          onPressed: startScanRCCard,
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
                                    if (e.key == 'rc_front_image' ||
                                        e.key == 'rc_photo' ||
                                        e.key == 'card_name_image' ||
                                        e.key == 'card_address_image' ||
                                        e.key == 'card_photo' ||
                                        e.key == 'dl_photo') {
                                      return Image.memory(
                                        const Base64Decoder().convert(
                                          e.value.toString(),
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
    );
  }
}
