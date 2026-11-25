import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../cards/fleet_card.dart';
import 'finance_models.dart';

extension FinanceLabels on AppLocalizations {
  String amount(int minor, {bool signed = false}) {
    final value = NumberFormat.currency(
      locale: localeName,
      symbol: '',
      decimalDigits: 2,
    ).format(minor / 100).trim();
    return isolate('${signed && minor > 0 ? '+' : ''}$value SYP');
  }

  String day(DateTime date) =>
      DateFormat.yMMMd(localeName).format(date.toUtc());

  String timestamp(DateTime instant) =>
      '${day(instant)} · ${DateFormat.Hm(localeName).format(instant.toUtc())} UTC';

  String volume(num count) =>
      liters(NumberFormat.decimalPattern(localeName).format(count));

  String cardStatus(CardStatus status) => switch (status) {
    CardStatus.active => active,
    CardStatus.stopped => stopped,
  };

  String fuelProduct(FuelProduct value) => switch (value) {
    FuelProduct.diesel => diesel,
    FuelProduct.benzene => benzene,
    FuelProduct.premium => premium,
  };

  String operationLabel(OperationType type) => switch (type) {
    OperationType.refill => refill,
    OperationType.withdraw => withdraw,
    OperationType.subscription => subscription,
    OperationType.forfeiture => forfeiture,
    OperationType.deposit => deposit,
    OperationType.initial => initial,
  };
}

String isolate(String code) => '\u2066$code\u2069';
