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

  test(
    'sends the question and optional company notes without source IDs',
    () async {
      final gemini = SupportGemini((prompt) async {
        final request = jsonDecode(prompt) as Map<String, dynamic>;
        expect(request['question'], cardQuestion);
        expect(request['firstTurn'], isTrue);
        expect(
          request['referenceNotes'],
          contains(catalog.findAnswer(cardQuestion)?.onlinePassage),
        );
        return 'البطاقة مسبقة الدفع.';
      });

      expect(
        await gemini.answer(catalog, cardQuestion, firstTurn: true),
        'البطاقة مسبقة الدفع.',
      );
    },
  );

  test(
    'sends questions even when notes are unavailable and returns the model reply unchanged',
    () async {
      const question = 'Explain this sample URL https://example.invalid/123456';
      final answer =
          'Response with a link https://example.invalid and more text. ' * 60;
      final gemini = SupportGemini((prompt) async {
        expect(jsonDecode(prompt), {'question': question, 'firstTurn': true});
        return answer;
      });

      expect(await gemini.answer(null, question, firstTurn: true), answer);
    },
  );

  test(
    'lets Gemini decide how to answer a question without a catalog match',
    () async {
      const question = 'مين المدير العام؟';
      final gemini = SupportGemini((prompt) async {
        expect(jsonDecode(prompt), {'question': question, 'firstTurn': true});
        return 'ما عندي معلومات مؤكدة عن الاسم.';
      });

      expect(
        await gemini.answer(catalog, question, firstTurn: true),
        'ما عندي معلومات مؤكدة عن الاسم.',
      );
    },
  );

  test('includes the previous provider turn for follow-ups', () async {
    const previousReply = 'تستخدم البطاقة بمحطات محددة.';
    final gemini = SupportGemini((prompt) async {
      final request = jsonDecode(prompt) as Map<String, dynamic>;
      expect(request['firstTurn'], isFalse);
      expect(request['previousTurn'], {
        'question': cardQuestion,
        'reply': previousReply,
      });
      expect(
        request['referenceNotes'],
        contains(
          catalog.entries
              .firstWhere((entry) => entry.id == 'company-card-network')
              .onlinePassage,
        ),
      );
      return 'يمكن استخدامها في المحطات التي تقبل البطاقة.';
    });

    final reply = await gemini.answer(
      catalog,
      'طيب وين فيني استعملها؟',
      firstTurn: false,
      previous: (question: cardQuestion, reply: previousReply),
    );
    expect(reply, 'يمكن استخدامها في المحطات التي تقبل البطاقة.');
  });

  test('provider exceptions leave the local answer available', () async {
    final gemini = SupportGemini((_) async => throw const FormatException());
    expect(await gemini.answer(catalog, cardQuestion, firstTurn: true), isNull);
    expect(catalog.findAnswer(cardQuestion)?.id, 'company-card');
  });
}
