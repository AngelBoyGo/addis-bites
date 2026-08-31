import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app_root.dart';

/// Sentry crash-reporting DSN (E1 in OPS.md). Safe to embed — DSNs are
/// client-side identifiers, not secrets (docs.sentry.io/concepts/key-terms/dsn-explainer).
const String _sentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue: 'https://2d0241e1e4be6afd512997a8c99618af@o4512005096669184.ingest.us.sentry.io/4512005116526592',
);

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.environment = 'production';
      options.tracesSampleRate = 0.1;
      options.sendDefaultPii = false; // PDPP 1321/2024: minimise personal data
    },
    appRunner: () => runApp(const ProviderScope(
      child: AppRoot(),
    )),
  );
}
