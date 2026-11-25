import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'support_catalog.dart';
import 'support_firebase_options.dart';

class SupportGemini {
  const SupportGemini(this._generate);

  final Future<String?> Function(String request) _generate;

  Future<String?> answer(
    SupportCatalog? catalog,
    String question, {
    required bool firstTurn,
    ({String question, String reply})? previous,
  }) async {
    final previousTopic = previous == null
        ? null
        : catalog?.findAnswer(previous.question);
    final sources =
        catalog?.onlineSourcesFor(question, previous: previousTopic) ??
        const [];
    final request = jsonEncode({
      'question': question,
      'firstTurn': firstTurn,
      if (previous != null)
        'previousTurn': {
          'question': previous.question,
          'reply': previous.reply,
        },
      if (sources.isNotEmpty)
        'referenceNotes': [for (final source in sources) source.onlinePassage],
    });

    try {
      final reply = await _generate(request);
      return reply == null || reply.trim().isEmpty ? null : reply;
    } on Exception {
      return null;
    }
  }

  static SupportGemini? configured() {
    const offlineOnly = bool.fromEnvironment('SUPPORT_OFFLINE_ONLY');
    if (offlineOnly ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    const apiKey = String.fromEnvironment('SUPPORT_FIREBASE_API_KEY');
    const appId = String.fromEnvironment('SUPPORT_FIREBASE_APP_ID');
    const projectId = String.fromEnvironment('SUPPORT_FIREBASE_PROJECT_ID');
    const senderId = String.fromEnvironment('SUPPORT_FIREBASE_SENDER_ID');
    const overrides = [apiKey, appId, projectId, senderId];
    if (overrides.every((value) => value.isEmpty)) {
      return SupportGemini(
        _FirebaseSupportClient(supportFirebaseOptions).generate,
      );
    }
    if (overrides.any((value) => value.isEmpty)) return null;
    final client = _FirebaseSupportClient(
      const FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        projectId: projectId,
        messagingSenderId: senderId,
      ),
    );
    return SupportGemini(client.generate);
  }
}

class _FirebaseSupportClient {
  _FirebaseSupportClient(this.options);

  final FirebaseOptions options;
  Future<GenerativeModel>? _model;

  Future<String?> generate(String request) async {
    final initializing = _model ??= _createModel();
    final GenerativeModel model;
    try {
      model = await initializing;
    } on Exception {
      if (identical(_model, initializing)) _model = null;
      rethrow;
    }
    return (await model.generateContent([Content.text(request)])).text;
  }

  Future<GenerativeModel> _createModel() async {
    const name = 'golden-gate-support';
    final app =
        Firebase.apps.where((app) => app.name == name).firstOrNull ??
        await Firebase.initializeApp(name: name, options: options);
    await FirebaseAppCheck.instanceFor(app: app).activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
    return FirebaseAI.googleAI(
      app: app,
      useLimitedUseAppCheckTokens: true,
    ).generativeModel(
      model: 'gemini-3.5-flash-lite',
      systemInstruction: Content.system(
        'Your name is Golden Gate AI Assistant. You may introduce yourself in one short '
        'sentence only when firstTurn is true. Otherwise start with the answer, without '
        'a greeting, your name, or a description of your role, even if the previous reply '
        'included one. If the user asks who you are or what your name is, answer by name. '
        'Follow these introduction rules for related and unrelated questions alike. '
        'Reply in Arabic by default and follow the user’s language preference when specified. '
        'The question field is the latest user message. The previous turn and reference notes, '
        'when supplied, are optional context that can help you answer it. '
        'Decide whether the question relates to Golden Gate, the company’s services, '
        'its app or website, or this assistant. General questions and follow-ups about them '
        'are in scope. Answer related questions even when there are no reference notes. '
        'If the question is unrelated, briefly explain what you can help with.',
      ),
    );
  }
}
