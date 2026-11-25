import '../../app/portal_destinations.dart';
import '../../demo/demo_fixtures.dart';

class SupportEntry {
  const SupportEntry({
    required this.id,
    required this.title,
    required this.example,
    required this.passage,
    required this.terms,
    required this.guideSection,
    required this.subject,
    required this.route,
    required this.sourceUrl,
    this.publicPassage,
  });

  final String id;
  final String title;
  final String? example;
  final String passage;
  final List<String> terms;
  final String? guideSection;
  final String? subject;
  final String? route;
  final Uri? sourceUrl;
  final String? publicPassage;

  String get onlinePassage => publicPassage ?? passage;

  Iterable<String> get phrases => [title, ?example, ...terms];
}

class SupportCatalog {
  static const assistantIdentityId = 'assistant-identity';

  SupportCatalog._(this.entries) {
    _index = [for (final entry in entries) _IndexedPassage(entry)];
    for (final passage in _index) {
      for (final term in passage.heading) {
        _frequency.update(term, (count) => count + 1, ifAbsent: () => 1);
      }
    }
  }

  late final List<_IndexedPassage> _index;
  final _frequency = <String, int>{};

  factory SupportCatalog.fromJson(Map<String, dynamic> data) {
    const allowedRoutes = {
      PortalDestinations.cards,
      PortalDestinations.support,
      PortalDestinations.balances,
      PortalDestinations.topUp,
      PortalDestinations.stations,
      PortalDestinations.subscriptions,
      PortalDestinations.prices,
    };
    final ids = <String>{};
    final entries = <SupportEntry>[];
    if (data case {
      'schemaVersion': 2,
      'entries': final List<dynamic> rows,
    } when rows.isNotEmpty) {
      for (final (index, row) in rows.indexed) {
        if (row
            case {
              'id': final String id,
              'title_ar': final String title,
              'passage_ar': final String passage,
              'terms': final List<dynamic> terms,
            }
            when id.trim().isNotEmpty &&
                _normalize(title).isNotEmpty &&
                passage.trim().isNotEmpty &&
                terms.every(
                  (alias) => alias is String && _normalize(alias).isNotEmpty,
                ) &&
                ids.add(id)) {
          final guideSection = row['guide_section'];
          final publicPassage = row['public_passage_ar'];
          final example = row['example_ar'];
          final subject = row['subject'];
          final route = row['app_route'];
          final source = row['source_url'];
          final sourceUrl = source is String ? Uri.tryParse(source) : null;
          if ((route == null && source == null && guideSection == null) ||
              !_validOptionalText(guideSection) ||
              !_validOptionalText(publicPassage) ||
              (publicPassage != null && !_isOfficialSource(sourceUrl)) ||
              !_validOptionalText(example) ||
              !_validOptionalText(subject) ||
              (route != null && !allowedRoutes.contains(route)) ||
              (source != null && !_isOfficialSource(sourceUrl))) {
            throw FixtureException(
              SupportRepository.assetPath,
              'invalid destination in row ${index + 1}',
            );
          }
          entries.add(
            SupportEntry(
              id: id,
              title: title,
              example: example as String?,
              passage: passage,
              terms: List.unmodifiable(terms.cast<String>()),
              guideSection: guideSection as String?,
              subject: subject as String?,
              route: route as String?,
              sourceUrl: sourceUrl,
              publicPassage: publicPassage as String?,
            ),
          );
        } else {
          throw FixtureException(
            SupportRepository.assetPath,
            'invalid row ${index + 1}',
          );
        }
      }
      return SupportCatalog._(List.unmodifiable(entries));
    }
    throw const FixtureException(
      SupportRepository.assetPath,
      'invalid support catalog',
    );
  }

  final List<SupportEntry> entries;

  SupportEntry? get assistantIdentity =>
      entries.where((entry) => entry.id == assistantIdentityId).firstOrNull;

  SupportEntry? findAnswer(String question, {SupportEntry? previous}) {
    final query = _normalize(question);
    final exact = _index.where((passage) => passage.phrases.contains(query));
    if (exact.isNotEmpty) return exact.length == 1 ? exact.single.entry : null;

    final words = _tokens(query);
    if (words.isEmpty) return null;
    final paddedQuery = ' $query ';
    final direct = _index.where(
      (passage) => passage.phrases.any(
        (phrase) => phrase.contains(' ') && paddedQuery.contains(' $phrase '),
      ),
    );
    final refersBack =
        previous?.subject != null &&
        _followUpMarkers.any((marker) => paddedQuery.contains(' $marker '));
    if (refersBack) {
      final related = _index.where(
        (passage) => passage.entry.subject == previous!.subject,
      );
      final answer = _rank(related, words, contextual: true);
      if (answer != null) return answer;
    }
    if (direct.length > 1) return null;
    if (direct.isNotEmpty) {
      final passage = direct.single;
      final phraseCoversQuery = passage.phrases.any(
        (phrase) =>
            paddedQuery.contains(' $phrase ') &&
            _tokens(phrase).length / words.length >= .6,
      );
      if (phraseCoversQuery) return passage.entry;
    }
    return _rank(_index, words);
  }

  List<SupportEntry> onlineSourcesFor(
    String question, {
    SupportEntry? previous,
  }) {
    final query = _normalize(question);
    final words = _tokens(query);
    if (words.isEmpty) return const [];
    final matches = <({SupportEntry entry, double score})>[];
    for (final passage in _index) {
      if (passage.entry.id == assistantIdentityId) continue;
      final onlinePassage = passage.entry.onlinePassage;
      final shared = words.intersection(passage.heading);
      final exact = passage.phrases.contains(query);
      final sameSubject =
          previous?.subject != null &&
          previous!.subject == passage.entry.subject;
      final contextual =
          sameSubject &&
          _followUpMarkers.any((marker) => query.split(' ').contains(marker));
      if (!exact && shared.isEmpty && !contextual) continue;
      final score =
          _headingScore(passage, shared) +
          words
                  .intersection(_tokens(_normalize(onlinePassage)))
                  .difference(shared)
                  .length *
              .65 +
          (exact ? 10 : 0) +
          (sameSubject ? 2 : 0);
      matches.add((entry: passage.entry, score: score));
    }
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.take(4).map((match) => match.entry).toList(growable: false);
  }

  double _headingScore(_IndexedPassage passage, Set<String> words) =>
      words.fold<double>(0, (total, term) {
        final weight = 2 + 3 / _frequency[term]!;
        return total + weight + (passage.title.contains(term) ? 1 : 0);
      });

  SupportEntry? _rank(
    Iterable<_IndexedPassage> passages,
    Set<String> words, {
    bool contextual = false,
  }) {
    final matches = <({SupportEntry entry, double score})>[];
    for (final passage in passages) {
      final strong = words.intersection(passage.heading);
      final weak = words.intersection(passage.body).difference(strong);
      final matchedCount = strong.length + weak.length;
      final hasDistinctTerm = strong.any((term) => _frequency[term] == 1);
      if (strong.isEmpty && (!contextual || weak.isEmpty)) continue;
      if (!contextual &&
          (matchedCount / words.length < .49 ||
              (matchedCount == 1 && !hasDistinctTerm))) {
        continue;
      }

      final score = _headingScore(passage, strong) + weak.length * .65;
      matches.add((entry: passage.entry, score: score));
    }
    matches.sort((a, b) => b.score.compareTo(a.score));
    if (matches.isEmpty ||
        (matches.length > 1 && matches[0].score - matches[1].score < 1.2)) {
      return null;
    }
    return matches.first.entry;
  }
}

class _IndexedPassage {
  _IndexedPassage(this.entry)
    : phrases = entry.phrases.map(_normalize).toSet(),
      title = _tokens(_normalize(entry.title)),
      heading = _tokens(_normalize(entry.phrases.join(' '))),
      body = _tokens(_normalize(entry.passage));

  final SupportEntry entry;
  final Set<String> phrases;
  final Set<String> title;
  final Set<String> heading;
  final Set<String> body;
}

class SupportRepository {
  SupportRepository(this._loader);

  static const assetPath = 'assets/demo/standard/support.json';

  final FixtureLoader _loader;
  SupportCatalog? _catalog;

  Future<SupportCatalog> load() async =>
      _catalog ??= SupportCatalog.fromJson(await _loader.readObject(assetPath));
}

bool _validOptionalText(Object? value) =>
    value == null || (value is String && value.trim().isNotEmpty);

const _followUpMarkers = {
  'طيب',
  'طب',
  'فيها',
  'فيه',
  'عندهم',
  'عندن',
  'هناك',
  'كمان',
  'استخدمها',
  'استعملها',
  'بستخدمها',
  'بستعملها',
};

final _stopWords = _normalize(
  'من في عن على إلى مع هل ما شو شنو كيف أين وين متى ايمتى عند لدى '
  'لو سمحت مرحبا بدي بدنا فيني بقدر اذا كان هي هذا هذه شوفي بدو '
  'يا ريت اللي عندي تبعي إلي يمكن ممكن فيكم بتقدروا حدن '
  'شركة البوابة الذهبية تبعكم اليوم سؤال خدمة عملاء '
  'طيب طب فيها فيه عندهم عندن هناك كمان and the to a of for is i can how what where',
).split(' ').map(_baseWord).toSet();

const _wordGroups = [
  'محطه محطات station stations بمحطه',
  'بطاقه بطاقات بطاقتي بطاقتك كرت كروت كرتي كارت card cards',
  'اصدار استخراج طلع بطلع تطلع احصل استلم استلام تسليم',
  'رصيد رصيدي ارصده balance',
  'شحن اشحن بشحن تعبئه عبي عبّي recharge topup',
  'مازوت ديزل diesel',
  'بنزين بنزينه benzine gasoline',
  'وقود محروقات مشتقات fuel',
  'حواله حوالتي تحويل تحويلات تحويله transfer',
  'مده بياخد بياخدوا بتاخد وقت ساعات ساعه يؤخذ time',
  'وصول توصل بتوصل بتوصلني يصل يظهر بيظهر مبين انضاف يضاف بينضاف لينضاف تشوف ظهر',
  'اشتراك اشتراكات اشتراكي subscription',
  'تسديد سداد تسدد سدد سددت تسديده دفع دفعت بدفع payment',
  'سعر اسعار قيمه تكلفه رسوم قيمتها قديش كم cost price',
  'تاخر تاخرت تاخير متاخر طولت',
  'شهري شهريه شهر شهرا اشهر شهور monthly',
  'وقف توقف تتوقف واقفه بتتوقف موقفه suspended',
  'عنوان موقع وينها موقعها موقعهن لوكيشن location address',
  'توفر توافر متوفر موجود متاح متوفره',
  'رقم تلفون هاتف موبايل phone',
  'شامكاش shamcash',
  'استخدام استخدم استخدمها استعملها بستخدمها بستعملها use',
];

final _synonyms = {
  for (final group in _wordGroups)
    for (final word in group.split(' '))
      _normalize(word): group.split(' ').first,
};

Set<String> _tokens(String text) => {
  for (final word in text.split(' ').map(_baseWord))
    if (word.isNotEmpty && !_stopWords.contains(word)) _synonyms[word] ?? word,
};

String _baseWord(String token) {
  if (token.length > 4 &&
      (token.startsWith('وال') || token.startsWith('بال'))) {
    return token.substring(3);
  }
  if (token.length > 3 && (token.startsWith('ال') || token.startsWith('لل'))) {
    return token.substring(2);
  }
  return token;
}

bool _isOfficialSource(Uri? url) =>
    url != null &&
    url.scheme == 'https' &&
    url.host == 'goldengate.sy' &&
    url.userInfo.isEmpty &&
    !url.hasPort &&
    url.path == '/' &&
    !url.hasQuery;

final _arabicMarks = RegExp(r'[\u064b-\u065f\u0670\u0640]');
final _alefVariants = RegExp('[أإآٱ]');
final _arabicDigits = RegExp(r'[٠-٩۰-۹]');
final _wordSeparators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

String _normalize(String text) => text
    .toLowerCase()
    .replaceAll(_arabicMarks, '')
    .replaceAll(_alefVariants, 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAllMapped(_arabicDigits, (digit) {
      final code = digit[0]!.codeUnitAt(0);
      const arabicZero = 0x0660;
      const persianZero = 0x06f0;
      return (code - (code < persianZero ? arabicZero : persianZero))
          .toString();
    })
    .replaceAll(_wordSeparators, ' ')
    .trim();
