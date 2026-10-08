import 'package:flutter/foundation.dart';

import '../domain/waitlist_entry.dart';
import '../domain/waitlist_repository.dart';

class WaitlistController extends ChangeNotifier {
  WaitlistController(this._repository);

  final WaitlistRepository _repository;

  List<WaitlistEntry> _entries = const [];
  int _nextTicketNumber = 1;
  bool _isLoading = true;
  String? _errorMessage;

  List<WaitlistEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _entries = await _repository.loadEntries();
      _nextTicketNumber = await _repository.loadNextTicketNumber();

      final maxTicket = _entries.fold<int>(
        0,
        (max, entry) => entry.ticketNumber > max ? entry.ticketNumber : max,
      );
      if (_nextTicketNumber <= maxTicket) {
        _nextTicketNumber = maxTicket + 1;
        await _repository.save(_entries, _nextTicketNumber);
      }
    } catch (_) {
      _errorMessage = 'Could not load the waitlist.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addParty({
    required String name,
    required int partySize,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || partySize <= 0) return false;

    final entry = WaitlistEntry(
      ticketNumber: _nextTicketNumber,
      name: trimmedName,
      partySize: partySize,
    );

    final updatedEntries = [..._entries, entry];

    try {
      await _repository.save(updatedEntries, _nextTicketNumber + 1);
      _entries = updatedEntries;
      _nextTicketNumber++;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Could not save the new party.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeParty(int ticketNumber) async {
    final updatedEntries = _entries
        .where((entry) => entry.ticketNumber != ticketNumber)
        .toList(growable: false);

    if (updatedEntries.length == _entries.length) return false;

    try {
      await _repository.save(updatedEntries, _nextTicketNumber);
      _entries = updatedEntries;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Could not remove the party.';
      notifyListeners();
      return false;
    }
  }
}
