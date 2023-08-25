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
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardPinController = TextEditingController();
  late final TabController _tabController;
  int _tabIndex = 0;
  late final StreamSubscription _progressSub;
  String? _progress;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    _progressSub = _flutterLibjeidPlugin.onProgress.listen((event) {
      if (mounted) {
        setState(() {
          _progress = event;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _progressSub.cancel();
    super.dispose();
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
        cardNumber: _cardNumberController.text,
      );
      if (mounted) {
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
        cardPin: _cardPinController.text,
      );
      if (mounted) {
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
                tabs: const [
                  SizedBox(height: 30, child: Text('RC Card')),
                  SizedBox(height: 30, child: Text('IN Card'))
                ],
                onTap: (index) {
                  setState(() {
                    _tabIndex = index;
                    _data = Map.from({});
                    _error = null;
                  });
                },
              ),
              const SizedBox(height: 10),
              AnimatedCrossFade(
                firstChild: Column(
                  children: [
                    TextFormField(
                      maxLength: 12,
                      controller: _cardNumberController,
                      decoration: const InputDecoration(
                        hintText: 'Input your residence card number',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: startScanRCCard,
                      child: const Text('Scan RC Card'),
                    ),
                  ],
                ),
                secondChild: Column(
                  children: [
                    TextFormField(
                      controller: _cardPinController,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        hintText: 'Input your number card pin',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: startScanINCard,
                      child: const Text('Scan IN Card'),
                    ),
                  ],
                ),
                crossFadeState: _tabIndex == 0
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
              ),
              const SizedBox(height: 20),
              if (_progress?.isNotEmpty ?? false)
                Text(
                  'Progressing: $_progress',
                ),
              if (_error?.isNotEmpty ?? false)
                Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: _tabIndex == 0
                      ? _RCCardResult(data: _data)
                      : _INCardResult(data: _data),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RCCardResult extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RCCardResult({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (data.containsKey('rc_front_image'))
          Stack(
            children: [
              Image.memory(
                const Base64Decoder().convert(
                  data['rc_front_image'],
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Image.memory(
                  const Base64Decoder().convert(
                    data['rc_photo'],
                  ),
                  width: 90,
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        if (data.isNotEmpty) ...[
          const Text('Other data'),
          const SizedBox(height: 10),
          ...data.entries.map(
            (e) => e.key == 'rc_front_image' || e.key == 'rc_photo'
                ? const SizedBox()
                : Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.key)),
                        Expanded(
                          flex: 2,
                          child: Text(
                            e.value.toString(),
                          ),
                        )
                      ],
                    ),
                  ),
          )
        ],
      ],
    );
  }
}

class _INCardResult extends StatelessWidget {
  final Map<String, dynamic> data;
  const _INCardResult({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (data.containsKey('card_name_image'))
          Image.memory(
            const Base64Decoder().convert(
              data['card_name_image'],
            ),
          ),
        const SizedBox(height: 10),
        if (data.containsKey('card_address_image'))
          Image.memory(
            const Base64Decoder().convert(
              data['card_address_image'],
            ),
          ),
        const SizedBox(height: 10),
        if (data.containsKey('card_photo'))
          Image.memory(
            const Base64Decoder().convert(
              data['card_photo'],
            ),
          ),
        const SizedBox(height: 10),
        if (data.isNotEmpty) ...[
          const Text('Other data'),
          const SizedBox(height: 10),
          ...data.entries.map(
            (e) => e.key == 'card_name_image' ||
                    e.key == 'card_address_image' ||
                    e.key == 'card_photo'
                ? const SizedBox()
                : Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.key)),
                        Expanded(
                          flex: 2,
                          child: Text(
                            e.value.toString(),
                          ),
                        )
                      ],
                    ),
                  ),
          )
        ],
      ],
    );
  }
}
