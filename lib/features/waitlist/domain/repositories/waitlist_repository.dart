import '../entities/waitlist_entry.dart';

abstract interface class WaitlistRepository {
  Future<List<WaitlistEntry>> loadEntries();
  Future<int> loadNextTicketNumber();
  Future<void> save(List<WaitlistEntry> entries, int nextTicketNumber);
}
