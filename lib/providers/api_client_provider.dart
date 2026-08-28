import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';

/// Single [ApiClient] instance (reads API_BASE via dart-define).
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());