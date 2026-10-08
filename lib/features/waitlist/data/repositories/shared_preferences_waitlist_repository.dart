import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/waitlist_entry.dart';
import '../../domain/waitlist_repository.dart';

class SharedPreferencesWaitlistRepository implements WaitlistRepository {
  SharedPreferencesWaitlistRepository(this._preferences);

  static const _stateKey = 'waitlist.state';

  final SharedPreferences _preferences;

  Map<String, dynamic>? _readState() {
    final raw = _preferences.getString(_stateKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Invalid persisted waitlist state.');
      }
      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      rethrow;
    } on TypeError {
      throw const FormatException('Invalid persisted waitlist state.');
    }
  }

  List<WaitlistEntry> _decodeEntries(dynamic rawEntries) {
    if (rawEntries is! List) {
      throw const FormatException('Invalid persisted waitlist entries.');
    }

    final entries = rawEntries.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid persisted waitlist entry.');
      }
      return WaitlistEntry.fromJson(Map<String, dynamic>.from(item));
    }).toList(growable: false);

    final tickets = entries.map((entry) => entry.ticketNumber).toSet();
    if (tickets.length != entries.length) {
      throw const FormatException('Duplicate ticket number in storage.');
    }

    if (entries.any(
      (entry) =>
          entry.ticketNumber < 1 ||
          entry.partySize <= 0 ||
          entry.name.trim().isEmpty,
    )) {
      throw const FormatException('Invalid waitlist entry in storage.');
    }

    return entries;
  }

  @override
  Future<List<WaitlistEntry>> loadEntries() async {
    final state = _readState();
    if (state == null) return [];
    return _decodeEntries(state['entries']);
  }

  @override
  Future<int> loadNextTicketNumber() async {
    final state = _readState();
    if (state == null) return 1;

    final value = state['nextTicketNumber'];
    if (value is! int || value < 1) {
      throw const FormatException('Invalid next ticket number in storage.');
    }

    return value;
  }

  @override
  Future<void> save(
    List<WaitlistEntry> entries,
    int nextTicketNumber,
  ) async {
    if (nextTicketNumber < 1) {
      throw ArgumentError.value(nextTicketNumber, 'nextTicketNumber');
    }

    final encoded = jsonEncode({
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
      'nextTicketNumber': nextTicketNumber,
    });

    final saved = await _preferences.setString(_stateKey, encoded);
    if (!saved) {
      throw StateError('Failed to persist the waitlist.');
    }
  }
}
