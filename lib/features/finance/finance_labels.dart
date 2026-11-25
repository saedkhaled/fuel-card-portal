import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../cards/fleet_card.dart';
import 'finance_models.dart';

extension FinanceLabels on AppLocalizations {
  String amount(int minor, {bool signed = false}) =>
      isolate('${amountValue(minor, signed: signed)} SYP');

  String amountValue(int minor, {bool signed = false}) {
    final value = NumberFormat.currency(
      locale: localeName,
      symbol: '',
      decimalDigits: 2,
    ).format(minor / 100).replaceAll(_directionMarks, '').trim();
    return '${signed && minor > 0 ? '+' : ''}$value';
  }

  String day(DateTime date) =>
      DateFormat.yMMMd(localeName).format(date.toUtc());

  String timestamp(DateTime instant) {
    final time = DateFormat.Hm(localeName).format(instant.toUtc());
    return '${day(instant)} · ${isolate('$time UTC')}';
  }

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

// Intl can put an RTL mark before the minus sign in Arabic currency values.
final _directionMarks = RegExp(r'[\u061c\u200e\u200f]');

String isolate(String code) => '\u2066$code\u2069';
