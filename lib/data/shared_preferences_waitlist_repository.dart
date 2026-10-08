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
      if (decoded is! List) {
        throw const FormatException('Invalid persisted waitlist data.');
      }

      final entries = decoded.map((item) {
        if (item is! Map) {
          throw const FormatException('Invalid persisted waitlist entry.');
        }
        return WaitlistEntry.fromJson(Map<String, dynamic>.from(item));
      }).toList(growable: false);

      final tickets = entries.map((entry) => entry.ticketNumber).toSet();
      if (tickets.length != entries.length) {
        throw const FormatException('Duplicate ticket number in storage.');
      }
      if (entries.any((entry) => entry.partySize <= 0 || entry.name.trim().isEmpty)) {
        throw const FormatException('Invalid waitlist entry in storage.');
      }

      return entries;
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
