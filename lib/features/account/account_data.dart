import '../../demo/demo_fixtures.dart';
import '../finance/fleet_data.dart';
import '../stations/station_network.dart' show NetworkText;

class AccountContact {
  const AccountContact(this.name, this.phone, this.email);
  final NetworkText name;
  final String phone;
  final String email;
}

class SubscriptionInvoice {
  const SubscriptionInvoice(
    this.id,
    this.issuedOn,
    this.paid,
    this.amountMinor,
  );
  final String id;
  final DateTime issuedOn;
  final bool paid;
  final int amountMinor;
}

class CardSubscription {
  const CardSubscription(this.exempt, this.invoices);
  final bool exempt;
  final List<SubscriptionInvoice> invoices;

  SubscriptionInvoice? get lastPayment =>
      invoices.where((invoice) => invoice.paid).firstOrNull;
}

class DemoTopUp {
  const DemoTopUp(
    this.destination,
    this.qrPayload,
    this.instructions,
    this.template,
  );
  final String destination;
  final String qrPayload;
  final NetworkText instructions;
  final String template;

  String note(String card, String plate) => template.replaceAllMapped(
    RegExp(r'\{(card|plate)\}'),
    (match) => match[1] == 'card' ? card : plate,
  );
}

class AccountFaq {
  const AccountFaq(this.question, this.answer);
  final NetworkText question;
  final NetworkText answer;
}

class AccountProfile {
  const AccountProfile({
    required this.company,
    required this.city,
    required this.registration,
    required this.contact,
    required this.monthlyAmountMinor,
    required this.nextChargeOn,
    required this.subscriptions,
    required this.topUp,
    required this.faq,
  });

  final NetworkText company;
  final NetworkText city;
  final String registration;
  final AccountContact contact;
  final int monthlyAmountMinor;
  final DateTime nextChargeOn;
  final Map<String, CardSubscription> subscriptions;
  final DemoTopUp topUp;
  final List<AccountFaq> faq;
}

class InboxItem {
  const InboxItem({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.initiallyRead,
    this.stationId,
    this.bulletinId,
  });

  final String id;
  final DateTime at;
  final NetworkText title;
  final NetworkText body;
  final bool initiallyRead;
  final String? stationId;
  final String? bulletinId;
}

class AccountInbox {
  const AccountInbox(this.items, this.stationAlert);
  final List<InboxItem> items;
  final InboxItem? stationAlert;
}

class AccountData {
  const AccountData(this.profiles, this.inboxes);

  final Map<String, AccountProfile> profiles;
  final Map<String, AccountInbox> inboxes;

  static Future<AccountData> load(
    FixtureLoader loader,
    DemoFixtures fixtures,
    FleetData fleet,
  ) async {
    final accountPath = fixtures.files['account'];
    final inboxPath = fixtures.files['notifications'];
    if (accountPath == null || inboxPath == null) {
      throw const FixtureException(
        FixtureLoader.manifestPath,
        'missing account or notifications mapping',
      );
    }
    final ids = fixtures.accounts.map((account) => account.id).toSet();
    final account = _Record(accountPath, await loader.readObject(accountPath));
    final notifications = _Record(
      inboxPath,
      await loader.readObject(inboxPath),
    );
    final profiles = <String, AccountProfile>{};
    for (final row in account.rows('profiles')) {
      final id = row.string('accountId');
      if (!ids.contains(id) || profiles.containsKey(id)) {
        row.fail('invalid account ID');
      }
      final cardIds = fleet.forAccount(id).cards.map((card) => card.id).toSet();
      profiles[id] = _profile(row, cardIds);
    }
    final inboxes = <String, AccountInbox>{};
    for (final row in notifications.rows('inboxes')) {
      final id = row.string('accountId');
      if (!ids.contains(id) || inboxes.containsKey(id)) {
        row.fail('invalid inbox account ID');
      }
      final itemIds = <String>{};
      final items = [
        for (final item in row.rows('items')) _notification(item, itemIds),
      ];
      final event = row.optionalRecord('stationAlert');
      final alert = event == null ? null : _notification(event, itemIds);
      if (alert != null && (alert.stationId == null || alert.initiallyRead)) {
        row.fail('invalid station alert');
      }
      inboxes[id] = AccountInbox(List.unmodifiable(items), alert);
    }
    if (profiles.length != ids.length) account.fail('missing profile');
    if (inboxes.length != ids.length) notifications.fail('missing inbox');
    return AccountData(Map.unmodifiable(profiles), Map.unmodifiable(inboxes));
  }

  static AccountProfile _profile(_Record row, Set<String> cardIds) {
    final contact = row.record('contact');
    final subscription = row.record('subscription');
    final topUp = row.record('topUp');
    final destination = topUp.string('destination');
    final qr = topUp.string('qrPayload');
    final template = topUp.string('transferNoteTemplate');
    if (!destination.startsWith('DEMO-') ||
        !qr.startsWith('FLEET-CARDS-DEMO:') ||
        !RegExp(r'^FLEET-CARDS-DEMO:[A-Z0-9-]{1,100}$').hasMatch(qr) ||
        !template.startsWith('DEMO ') ||
        !template.contains('{card}') ||
        !template.contains('{plate}')) {
      topUp.fail('expected inert demo destination, QR and transfer note');
    }

    final subscriptions = <String, CardSubscription>{};
    final invoiceIds = <String>{};
    for (final item in subscription.rows('cards')) {
      final cardId = item.string('cardId');
      if (!cardIds.contains(cardId) || subscriptions.containsKey(cardId)) {
        item.fail('unknown or duplicate subscription card');
      }
      final exempt = item.value<bool>('exempt');
      final invoices = <SubscriptionInvoice>[];
      for (final invoice in item.rows('invoices')) {
        final id = invoice.string('id');
        final status = invoice.string('status');
        final method = invoice.optionalString('paymentMethod');
        if (!invoiceIds.add(id) ||
            exempt ||
            !((status == 'paid' && method == 'balance') ||
                (status == 'unpaid' && method == null))) {
          invoice.fail('invalid invoice');
        }
        invoices.add(
          SubscriptionInvoice(
            id,
            invoice.date('issuedOn'),
            status == 'paid',
            invoice.minor('amountMinor'),
          ),
        );
      }
      invoices.sort((a, b) => b.issuedOn.compareTo(a.issuedOn));
      subscriptions[cardId] = CardSubscription(
        exempt,
        List.unmodifiable(invoices),
      );
    }
    if (subscriptions.length != cardIds.length) {
      subscription.fail('missing subscription card');
    }

    return AccountProfile(
      company: row.localized('company'),
      city: row.localized('city'),
      registration: row.string('registration'),
      contact: AccountContact(
        contact.localized('name'),
        contact.string('phone'),
        contact.string('email'),
      ),
      monthlyAmountMinor: subscription.minor('monthlyAmountMinor'),
      nextChargeOn: subscription.date('nextChargeOn'),
      subscriptions: Map.unmodifiable(subscriptions),
      topUp: DemoTopUp(
        destination,
        qr,
        topUp.localized('instructions'),
        template,
      ),
      faq: List.unmodifiable([
        for (final item in row.rows('faq'))
          AccountFaq(item.localized('question'), item.localized('answer')),
      ]),
    );
  }

  static InboxItem _notification(_Record row, Set<String> ids) {
    final id = row.string('id');
    final station = row.optionalString('stationId');
    final bulletin = row.optionalString('bulletinId');
    final rawTime = row.string('at');
    final at = DateTime.tryParse(rawTime);
    if (!ids.add(id) ||
        (station != null && bulletin != null) ||
        at == null ||
        !rawTime.endsWith('Z') ||
        rawTime.length < 20 ||
        !at.toIso8601String().startsWith(rawTime.substring(0, 19))) {
      row.fail('invalid inbox item');
    }
    return InboxItem(
      id: id,
      at: at,
      title: row.localized('title'),
      body: row.localized('body'),
      initiallyRead: row.value<bool>('read'),
      stationId: station,
      bulletinId: bulletin,
    );
  }
}

class _Record {
  const _Record(this.path, this.fields);
  final String path;
  final Map<String, dynamic> fields;

  Never fail(String reason) => throw FixtureException(path, reason);

  T value<T>(String key) {
    final field = fields[key];
    if (field is T) return field;
    fail('invalid $key');
  }

  String string(String key) {
    final field = value<String>(key);
    if (field.trim().isEmpty) fail('empty $key');
    return field;
  }

  String? optionalString(String key) =>
      fields[key] == null ? null : string(key);
  _Record record(String key) =>
      _Record('$path.$key', value<Map<String, dynamic>>(key));
  _Record? optionalRecord(String key) =>
      fields[key] == null ? null : record(key);

  Iterable<_Record> rows(String key) sync* {
    for (final (index, item) in value<List<dynamic>>(key).indexed) {
      if (item is! Map<String, dynamic>) fail('invalid $key item');
      yield _Record('$path.$key[$index]', item);
    }
  }

  NetworkText localized(String key) {
    final text = record(key);
    return NetworkText(text.string('en'), text.string('ar'));
  }

  int minor(String key) {
    final amount = value<int>(key);
    if (amount < 0) fail('negative $key');
    return amount;
  }

  DateTime date(String key) {
    final raw = string(key);
    final date = DateTime.tryParse('${raw}T00:00:00Z');
    if (date == null || date.toIso8601String().split('T').first != raw) {
      fail('invalid $key date');
    }
    return date;
  }
}
