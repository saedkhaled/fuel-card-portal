import 'dart:convert';
import 'dart:io';

import 'package:fleet_cards_demo/features/support/support_catalog.dart';
import 'package:fleet_cards_demo/features/support/support_gemini.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = SupportCatalog.fromJson(
    jsonDecode(File(SupportRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>,
  );
  const cardQuestion = 'كيف بتشتغل بطاقة البوابة الذهبية؟';

  test('sends eligible excerpts and resolves a website citation', () async {
    late Map<String, dynamic> request;
    final gemini = SupportGemini((prompt) async {
      request = jsonDecode(prompt) as Map<String, dynamic>;
      return jsonEncode({
        'status': 'answer',
        'text': 'البطاقة مسبقة الدفع وتستخدمها في المحطات التي تقبلها.',
        'sourceId': 'company-card',
      });
    });

    final reply = await gemini.answer(catalog, cardQuestion);
    expect(reply?.source?.id, 'company-card');
    expect(reply?.source?.sourceUrl, isNotNull);
    final sources = request['sources'] as List<dynamic>;
    expect(sources.length, inInclusiveRange(1, 4));
    for (final source in sources) {
      final entry = catalog.entries.firstWhere((e) => e.id == source['id']);
      expect(source['passage'], entry.onlinePassage);
      expect(entry.sourceUrl ?? entry.guideSection ?? entry.route, isNotNull);
    }
    expect(request.keys, unorderedEquals(['question', 'sources']));
  });

  test('keeps private questions and payment credentials on-device', () async {
    var calls = 0;
    final gemini = SupportGemini((_) async {
      calls++;
      return null;
    });
    for (final question in [
      'شو حالة بطاقتي رقم ١٢٣٤٥٦؟',
      'متى بتوصل حوالتي شام كاش رقم 123456789؟',
      'بريدي customer@example.invalid',
      'كلمة السر: تجريبية',
    ]) {
      expect(await gemini.answer(catalog, question), isNull, reason: question);
      expect(calls, 0, reason: question);
    }
  });

  test('uses and cites guide-only passages for general questions', () async {
    final cases = {
      'إذا بعت حوالة شام كاش إمتى بيظهر الرصيد؟': 'guide-transfer-time',
      'قديش قيمتها رسوم الكرت الشهرية؟': 'guide-subscription',
    };
    for (final MapEntry(key: question, value: id) in cases.entries) {
      var calls = 0;
      final gemini = SupportGemini((prompt) async {
        calls++;
        final request = jsonDecode(prompt) as Map<String, dynamic>;
        final sources = request['sources'] as List<dynamic>;
        final source = sources.singleWhere((source) => source['id'] == id);
        final entry = catalog.entries.firstWhere((entry) => entry.id == id);
        expect(source['passage'], entry.passage);
        return jsonEncode({
          'status': 'answer',
          'text': entry.passage,
          'sourceId': id,
        });
      });
      final reply = await gemini.answer(catalog, question);
      expect(calls, 1, reason: question);
      expect(reply?.source?.id, id);
      expect(reply?.source?.guideSection, isNotEmpty);
      expect(reply?.source?.sourceUrl, isNull);
    }
  });

  test('rejects malformed responses, invented source IDs and links', () async {
    for (final raw in [
      'invalid JSON',
      '{"status":"answer","text":"تم","sourceId":"invented"}',
      '{"status":"answer","text":"تم","sourceId":"guide-station-21"}',
      '{"status":"answer","text":"https://example.invalid","sourceId":"company-card"}',
      '{"status":"no_answer","text":"غير معروف","sourceId":"company-card"}',
    ]) {
      final gemini = SupportGemini((_) async => raw);
      expect(await gemini.answer(catalog, cardQuestion), isNull, reason: raw);
    }
  });

  test(
    'asks Gemini who the manager is even without matching excerpts',
    () async {
      const question = 'مين المدير العام؟';
      expect(catalog.onlineSourcesFor(question), isEmpty);
      final gemini = SupportGemini((prompt) async {
        expect(jsonDecode(prompt), {'question': question, 'sources': []});
        return '{"status":"no_answer","text":"","sourceId":""}';
      });
      final reply = await gemini.answer(catalog, question);
      expect(reply, isNotNull);
      expect(reply?.text, isNull);
      expect(reply?.source, isNull);
      expect(reply?.outOfScope, isFalse);
    },
  );

  test('Gemini receives app instructions for common app questions', () async {
    const question = 'وين بشوف رصيد بطاقتي؟';
    final gemini = SupportGemini((prompt) async {
      final request = jsonDecode(prompt) as Map<String, dynamic>;
      expect(
        (request['sources'] as List<dynamic>).map((item) => item['id']),
        contains('check-balance'),
      );
      return '{"status":"answer","text":"افتح الأرصدة من قائمة المزيد.","sourceId":"check-balance"}';
    });
    final reply = await gemini.answer(catalog, question);
    expect(reply?.source?.route, '/balances');
  });

  test('app and website overview questions retrieve practical details', () {
    for (final (question, id) in [
      ('كيف فيني استخدم هالتطبيق؟', 'app-overview'),
      ('شو بيفيدني التطبيق؟', 'app-overview'),
      ('What is the application good for?', 'app-overview'),
      ('شو فيني اعمل على الموقع؟', 'website-overview'),
    ]) {
      expect(
        catalog.onlineSourcesFor(question).map((entry) => entry.id),
        contains(id),
        reason: question,
      );
    }
  });

  test(
    'accepts practical guidance for a related question without a citation',
    () async {
      const question = 'شو بتنصحني أعمل أول شي قبل ما اتواصل مع الشركة؟';
      final gemini = SupportGemini((prompt) async {
        expect(jsonDecode(prompt)['question'], question);
        return '{"status":"guidance","text":"حدّد شو الخدمة اللي بتحتاجها وجهّز سؤالك قبل التواصل.","sourceId":""}';
      });
      final reply = await gemini.answer(catalog, question);
      expect(reply?.text, contains('حدّد شو الخدمة'));
      expect(reply?.source, isNull);
      expect(reply?.outOfScope, isFalse);
    },
  );

  test('Gemini receives unrelated questions and declines them', () async {
    const question = 'احكيلي وصفة كيك';
    final gemini = SupportGemini((prompt) async {
      expect(jsonDecode(prompt)['question'], question);
      return '{"status":"out_of_scope","text":"","sourceId":""}';
    });
    final reply = await gemini.answer(catalog, question);
    expect(reply?.outOfScope, isTrue);
    expect(reply?.source, isNull);
  });

  test(
    'uses the bundled identity when Gemini recognizes an introduction',
    () async {
      const question = 'Would you mind telling me who I am talking to?';
      final gemini = SupportGemini((prompt) async {
        expect(jsonDecode(prompt)['question'], question);
        return '{"status":"identity","text":"","sourceId":""}';
      });
      final reply = await gemini.answer(catalog, question);
      expect(reply?.source, catalog.assistantIdentity);
      expect(catalog.findAnswer('شو اسمك؟'), catalog.assistantIdentity);
      expect(catalog.findAnswer('Who are you?'), catalog.assistantIdentity);
      expect(catalog.findAnswer(question), catalog.assistantIdentity);
    },
  );

  test('a card follow-up can send its previous public topic', () async {
    final gemini = SupportGemini((prompt) async {
      final request = jsonDecode(prompt) as Map<String, dynamic>;
      expect(request['previousTopic'], isNotNull);
      expect(
        (request['sources'] as List<dynamic>).map((item) => item['id']),
        contains('company-card-network'),
      );
      return '{"status":"answer","text":"يمكن استخدامها في المحطات التي تقبل البطاقة.","sourceId":"company-card-network"}';
    });
    final reply = await gemini.answer(
      catalog,
      'طيب وين فيني استعملها؟',
      previous: catalog.findAnswer(cardQuestion),
    );
    expect(reply?.source?.id, 'company-card-network');
  });

  test(
    'provider failures leave the existing Arabic answer available',
    () async {
      final gemini = SupportGemini(
        (_) async => throw const FormatException('fake'),
      );
      final local = catalog.findAnswer(cardQuestion);
      expect(local?.id, 'company-card');
      expect(await gemini.answer(catalog, cardQuestion), isNull);
    },
  );
}
