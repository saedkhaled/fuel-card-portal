import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../auth/session_controller.dart';
import 'finance_models.dart';
import 'fleet_data.dart';

AccountFinance accountFinance(BuildContext context) =>
    context.watch<FleetData>().forAccount(
      context.select<SessionController, String?>(
        (session) => session.accountId,
      ),
    );
