import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DemoAccount {
  const DemoAccount({
    required this.id,
    required this.phone,
    required this.code,
  });

  final String id;
  final String phone;
  final String code;
}

class DemoFixtures {
  const DemoFixtures({
    required this.scenario,
    required this.files,
    required this.accounts,
    required this.validity,
    required this.resendDelay,
    required this.failFirstRequest,
  });

  final String scenario;
  final Map<String, String> files;
  final List<DemoAccount> accounts;
  final Duration validity;
  final Duration resendDelay;
  final bool failFirstRequest;
}

final demoPhonePattern = RegExp(r'^09[0-9]{8}$');
final demoCodePattern = RegExp(r'^[0-9]{6}$');

class FixtureException implements Exception {
  const FixtureException(this.path, this.reason);

  final String path;
  final String reason;

  @override
  String toString() => 'Invalid demo fixture at $path ($reason)';
}

class FixtureLoader {
  const FixtureLoader(this.bundle);

  static const manifestPath = 'assets/demo/manifest.json';

  final AssetBundle bundle;

  Future<DemoFixtures> load({String? scenario}) async {
    final manifest = await readObject(manifestPath);
    if (manifest case {
      'schemaVersion': 1,
      'defaultScenario': final String defaultScenario,
      'scenarios': final Map<String, dynamic> scenarios,
    }) {
      final selected = scenario ?? defaultScenario;
      final entry = scenarios[selected];
      if (entry case {'files': final Map<String, dynamic> files}) {
        if (files['auth'] is! String ||
            files.values.any(
              (value) => value is! String || !value.startsWith('assets/demo/'),
            )) {
          throw FixtureException(manifestPath, 'invalid files for $selected');
        }
        final failOnce = entry['failOnce'];
        if (failOnce != null && failOnce != 'requestCode') {
          throw FixtureException(manifestPath, 'invalid failure for $selected');
        }
        final authPath = files['auth'] as String;
        final auth = await readObject(authPath);
        if (auth case {
          'validitySeconds': final int validity,
          'resendSeconds': final int resend,
          'accounts': final List<dynamic> accounts,
        } when resend > 0 && validity > resend && accounts.isNotEmpty) {
          return DemoFixtures(
            scenario: selected,
            files: Map.unmodifiable(files.cast<String, String>()),
            accounts: _parseAccounts(authPath, accounts),
            validity: Duration(seconds: validity),
            resendDelay: Duration(seconds: resend),
            failFirstRequest: failOnce == 'requestCode',
          );
        }
        throw FixtureException(authPath, 'invalid challenge settings');
      }
      throw FixtureException(manifestPath, 'unknown scenario $selected');
    }
    throw const FixtureException(manifestPath, 'unsupported manifest');
  }

  List<DemoAccount> _parseAccounts(String path, List<dynamic> records) {
    final ids = <String>{};
    final phones = <String>{};
    return List.unmodifiable([
      for (final (index, record) in records.indexed)
        switch (record) {
          {
            'id': final String id,
            'phone': final String phone,
            'code': final String code,
          }
              when id.isNotEmpty &&
                  demoPhonePattern.hasMatch(phone) &&
                  demoCodePattern.hasMatch(code) &&
                  ids.add(id) &&
                  phones.add(phone) =>
            DemoAccount(id: id, phone: phone, code: code),
          _ => throw FixtureException(path, 'invalid account at index $index'),
        },
    ]);
  }

  Future<Map<String, dynamic>> readObject(String path) async {
    try {
      final contents = await bundle.loadString(path, cache: false);
      final decoded = jsonDecode(contents);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FlutterError {
      throw FixtureException(path, 'asset unavailable');
    } on FormatException {
      throw FixtureException(path, 'malformed JSON');
    }
    throw FixtureException(path, 'expected a JSON object');
  }
}
