import '../../app/portal_destinations.dart';
import '../../demo/demo_fixtures.dart';

class SupportEntry {
  const SupportEntry({
    required this.id,
    required this.question,
    required this.answer,
    required this.aliases,
    required this.route,
    required this.sourceUrl,
  });

  final String id;
  final String question;
  final String answer;
  final List<String> aliases;
  final String? route;
  final Uri? sourceUrl;

  Iterable<String> get phrases => [question, ...aliases];
}

class SupportCatalog {
  SupportCatalog._(this.entries);

  factory SupportCatalog.fromJson(Map<String, dynamic> data) {
    const allowedRoutes = {
      PortalDestinations.balances,
      PortalDestinations.topUp,
      PortalDestinations.stations,
      PortalDestinations.subscriptions,
      PortalDestinations.prices,
    };
    final ids = <String>{};
    final entries = <SupportEntry>[];
    if (data case {
      'schemaVersion': 1,
      'entries': final List<dynamic> rows,
    } when rows.isNotEmpty) {
      for (final (index, row) in rows.indexed) {
        if (row
            case {
              'id': final String id,
              'question_ar': final String question,
              'answer_ar': final String answer,
              'aliases': final List<dynamic> aliases,
            }
            when id.trim().isNotEmpty &&
                _normalize(question).isNotEmpty &&
                answer.trim().isNotEmpty &&
                aliases.every(
                  (alias) => alias is String && _normalize(alias).isNotEmpty,
                ) &&
                ids.add(id)) {
          final route = row['app_route'];
          final source = row['source_url'];
          final sourceUrl = source is String ? Uri.tryParse(source) : null;
          if ((route == null && source == null) ||
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
              question: question,
              answer: answer,
              aliases: List.unmodifiable(aliases.cast<String>()),
              route: route as String?,
              sourceUrl: sourceUrl,
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

  SupportEntry? findAnswer(String question) {
    final query = _normalize(question);
    final exact = entries
        .where((entry) => entry.phrases.map(_normalize).contains(query))
        .take(2)
        .toList();
    if (exact.isNotEmpty) return exact.length == 1 ? exact.single : null;

    final paddedQuery = ' $query ';
    final matches = entries
        .where(
          (entry) => entry.phrases
              .map(_normalize)
              .any(
                (phrase) =>
                    phrase.contains(' ') && paddedQuery.contains(' $phrase '),
              ),
        )
        .take(2)
        .toList();
    return matches.length == 1 ? matches.single : null;
  }
}

class SupportRepository {
  SupportRepository(this._loader);

  static const assetPath = 'assets/demo/standard/support.json';

  final FixtureLoader _loader;
  SupportCatalog? _catalog;

  Future<SupportCatalog> load() async =>
      _catalog ??= SupportCatalog.fromJson(await _loader.readObject(assetPath));
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
