import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../auth/session_controller.dart';
import 'account_data.dart';

AccountProfile? accountProfile(BuildContext context) =>
    context.watch<AccountData>().profiles[context
        .select<SessionController, String?>((session) => session.accountId)];
