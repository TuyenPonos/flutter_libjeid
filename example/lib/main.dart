import 'dart:convert';
import 'dart:developer';

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

class _MyAppState extends State<MyApp> {
  Map<String, dynamic> _data = {};
  String? _error;
  final _flutterLibjeidPlugin = FlutterLibjeid();
  final TextEditingController _cardNumberController = TextEditingController();

  @override
  void initState() {
    _cardNumberController.text = 'TJ22087934EA';
    super.initState();
  }

  Future<void> startScan() async {
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
      log(resp.toString());
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
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Libjeid example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                maxLength: 12,
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  hintText: 'Input card number',
                ),
              ),
              ElevatedButton(
                onPressed: startScan,
                child: const Text('Scan RC Card'),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_data.containsKey('rc_front_image'))
                          Stack(
                            children: [
                              Image.memory(
                                const Base64Decoder().convert(
                                  _data['rc_front_image'],
                                ),
                              ),
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Image.memory(
                                  const Base64Decoder().convert(
                                    _data['rc_photo'],
                                  ),
                                  width: 90,
                                ),
                              ),
                            ],
                          ),
                        if (_data.isNotEmpty)
                          Text(
                            _data.toString(),
                          ),
                      ],
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
