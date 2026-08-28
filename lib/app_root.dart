import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/telegram_adapter.dart';
import 'i18n/strings.dart';
import 'providers/locale_provider.dart';
import 'providers/session_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.build(ref);
    // Restore any persisted session from secure storage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionProvider.notifier).restore();
      // §9: inside Telegram, authenticate via initData (replaces SMS OTP).
      if (TelegramAdapter.isTelegram && TelegramAdapter.initData.isNotEmpty) {
        ref.read(sessionProvider.notifier).tgAuth(TelegramAdapter.initData);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final strings = Strings(locale);

    // §7.2: adapt to Telegram themeParams when running inside Telegram.
    final telegramTheme = TelegramAdapter.isTelegram
        ? AppTheme.fromTelegram(TelegramAdapter.themeParams)
        : null;

    return StringsScope(
      strings: strings,
      child: MaterialApp.router(
        title: 'Addis Bites',
        debugShowCheckedModeBanner: false,
        theme: telegramTheme ?? AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: _router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('am')],
      ),
    );
  }
}

/// Provides the Strings catalog down the tree via inherited widget.
class StringsScope extends InheritedWidget {
  const StringsScope({super.key, required this.strings, required super.child});
  final Strings strings;

  static Strings of(BuildContext context) =>
      (context.dependOnInheritedWidgetOfExactType<StringsScope>()?.strings) ??
      const Strings(LocaleId.en);

  @override
  bool updateShouldNotify(StringsScope old) => old.strings.locale != strings.locale;
}