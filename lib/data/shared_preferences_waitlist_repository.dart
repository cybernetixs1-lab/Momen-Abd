import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/waitlist_entry.dart';
import '../domain/waitlist_repository.dart';

class SharedPreferencesWaitlistRepository implements WaitlistRepository {
  SharedPreferencesWaitlistRepository(this._preferences);

  static const _entriesKey = 'waitlist.entries';
  static const _nextTicketKey = 'waitlist.next_ticket';

  final SharedPreferences _preferences;

  @override
  Future<List<WaitlistEntry>> loadEntries() async {
    final raw = _preferences.getString(_entriesKey);
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .map((item) => WaitlistEntry.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false);
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  @override
  Future<int> loadNextTicketNumber() async {
    final value = _preferences.getInt(_nextTicketKey);
    return value == null || value < 1 ? 1 : value;
  }

  @override
  Future<void> save(List<WaitlistEntry> entries, int nextTicketNumber) async {
    final encoded = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );

    final entriesSaved = await _preferences.setString(_entriesKey, encoded);
    final ticketSaved =
        await _preferences.setInt(_nextTicketKey, nextTicketNumber);

    if (!entriesSaved || !ticketSaved) {
      throw StateError('Failed to persist the waitlist.');
    }
  }
}
