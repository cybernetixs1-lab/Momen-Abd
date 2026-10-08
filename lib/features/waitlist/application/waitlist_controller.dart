import 'package:flutter/foundation.dart';

import '../domain/entities/waitlist_entry.dart';
import '../domain/repositories/waitlist_repository.dart';

class WaitlistController extends ChangeNotifier {
  WaitlistController(this._repository);

  final WaitlistRepository _repository;

  List<WaitlistEntry> _entries = const [];
  int _nextTicketNumber = 1;
  bool _isLoading = true;
  bool _isMutating = false;
  String? _errorMessage;

  List<WaitlistEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
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
      }
    } catch (_) {
      _entries = const [];
      _nextTicketNumber = 1;
      _errorMessage = 'Could not load the saved waitlist. Please retry.';
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
    if (_isMutating || trimmedName.isEmpty || partySize <= 0) return false;

    final entry = WaitlistEntry(
      ticketNumber: _nextTicketNumber,
      name: trimmedName,
      partySize: partySize,
    );

    final updatedEntries = [..._entries, entry];

    _isMutating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.save(updatedEntries, _nextTicketNumber + 1);
      _entries = updatedEntries;
      _nextTicketNumber++;
      return true;
    } catch (_) {
      _errorMessage = 'Could not save the new party.';
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> removeParty(int ticketNumber) async {
    if (_isMutating) return false;

    final updatedEntries = _entries
        .where((entry) => entry.ticketNumber != ticketNumber)
        .toList(growable: false);

    if (updatedEntries.length == _entries.length) return false;

    _isMutating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.save(updatedEntries, _nextTicketNumber);
      _entries = updatedEntries;
      return true;
    } catch (_) {
      _errorMessage = 'Could not remove the party.';
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
