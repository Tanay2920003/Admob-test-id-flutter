import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:advertising_id/advertising_id.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AdMob Test ID Fetcher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TestIdScreen(),
    );
  }
}

class TestIdScreen extends StatefulWidget {
  const TestIdScreen({super.key});

  @override
  State<TestIdScreen> createState() => _TestIdScreenState();
}

class _TestIdScreenState extends State<TestIdScreen> {
  static const _androidIdPlugin = AndroidId();
  String _testId = 'Fetching...';
  String _advertisingId = 'Fetching...';

  @override
  void initState() {
    super.initState();
    _fetchIds();
  }

  Future<void> _fetchIds() async {
    if (!Platform.isAndroid) {
      setState(() {
        _testId = 'Unsupported Platform';
        _advertisingId = 'Unsupported Platform';
      });
      return;
    }

    String? androidId;
    try {
      androidId = await _androidIdPlugin.getId();
    } on PlatformException {
      androidId = null;
    }

    String? advId;
    try {
      advId = await AdvertisingId.id(true);
    } on PlatformException {
      advId = null;
    }

    if (!mounted) return;

    setState(() {
      if (androidId != null && androidId.isNotEmpty) {
        var bytes = utf8.encode(androidId);
        var digest = md5.convert(bytes);
        _testId = digest.toString().toUpperCase();
      } else {
        _testId = 'Could not get Android ID';
      }

      if (advId != null && advId.isNotEmpty) {
        _advertisingId = advId;
      } else {
        _advertisingId = 'Could not get Advertising ID\n(Ensure Ads Personalization is enabled in Settings)';
      }
    });
  }

  Widget _buildIdCard(String title, String value, String description) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 15),
            SelectableText(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: value.length > 10 && !value.contains('Could not') ? () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard!')),
                );
              } : null,
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AdMob Test Device IDs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.perm_device_information, size: 60, color: Colors.deepPurple),
              const SizedBox(height: 20),
              _buildIdCard(
                'Advertising ID',
                _advertisingId,
                'Paste this exactly into the AdMob Website Dashboard\n(Advertising ID/IDFA field)',
              ),
              _buildIdCard(
                'MD5 Hashed Test ID',
                _testId,
                'Use this if you are adding test devices directly in your Flutter code via setTestDeviceIds()',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
