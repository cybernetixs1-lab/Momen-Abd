import 'package:flutter/foundation.dart';

import '../domain/entities/waitlist_entry.dart';
import '../domain/repositories/waitlist_repository.dart';

class RemovedWaitlistParty {
  const RemovedWaitlistParty({required this.entry, required this.index});

  final WaitlistEntry entry;
  final int index;
}

class WaitlistController extends ChangeNotifier {
  WaitlistController(this._repository);

  final WaitlistRepository _repository;

  List<WaitlistEntry> _entries = const [];
  int _nextTicketNumber = 1;
  bool _isLoading = true;
  bool _isMutating = false;
  bool _hasLoadError = false;
  String? _errorMessage;
  RemovedWaitlistParty? _lastRemoval;

  List<WaitlistEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  bool get hasLoadError => _hasLoadError;
  String? get errorMessage => _errorMessage;
  RemovedWaitlistParty? get lastRemoval => _lastRemoval;

  String? validateName(String name) =>
      name.trim().isEmpty ? 'Name is required.' : null;

  String? validatePartySize(int? partySize) =>
      partySize == null || partySize < 1
          ? 'Enter a whole number greater than 0.'
          : null;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _entries = await _repository.loadEntries();
      _nextTicketNumber = await _repository.loadNextTicketNumber();
      _hasLoadError = false;

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
      _hasLoadError = true;
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
    if (_isMutating ||
        validateName(trimmedName) != null ||
        validatePartySize(partySize) != null) {
      return false;
    }

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

    final index =
        _entries.indexWhere((entry) => entry.ticketNumber == ticketNumber);
    if (index < 0) return false;
    final removedEntry = _entries[index];
    final updatedEntries = [..._entries]..removeAt(index);

    _isMutating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.save(updatedEntries, _nextTicketNumber);
      _entries = updatedEntries;
      _lastRemoval = RemovedWaitlistParty(entry: removedEntry, index: index);
      return true;
    } catch (_) {
      _errorMessage = 'Could not remove the party.';
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> undoLastRemoval() async {
    final removal = _lastRemoval;
    if (_isMutating || removal == null) return false;

    if (_entries.any(
      (entry) => entry.ticketNumber == removal.entry.ticketNumber,
    )) {
      _errorMessage = 'That ticket is already in the waitlist.';
      notifyListeners();
      return false;
    }

    final updatedEntries = [..._entries]
      ..insert(removal.index.clamp(0, _entries.length).toInt(), removal.entry);

    _isMutating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.save(updatedEntries, _nextTicketNumber);
      _entries = updatedEntries;
      _lastRemoval = null;
      return true;
    } catch (_) {
      _errorMessage = 'Could not restore the party.';
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
