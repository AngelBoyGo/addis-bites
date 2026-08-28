import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide user settings that affect rendering (persisted via shared_prefs).
final dataSaverProvider =
    StateNotifierProvider<DataSaverNotifier, bool>((ref) => DataSaverNotifier());

class DataSaverNotifier extends StateNotifier<bool> {
  DataSaverNotifier() : super(false);
  void set(bool v) => state = v;
  void toggle() => state = !state;
}