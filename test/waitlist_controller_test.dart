import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_waitlist/application/waitlist_controller.dart';
import 'package:restaurant_waitlist/domain/waitlist_entry.dart';
import 'package:restaurant_waitlist/domain/waitlist_repository.dart';

class FakeWaitlistRepository implements WaitlistRepository {
  List<WaitlistEntry> entries = [];
  int nextTicketNumber = 1;

  @override
  Future<List<WaitlistEntry>> loadEntries() async => entries;

  @override
  Future<int> loadNextTicketNumber() async => nextTicketNumber;

  @override
  Future<void> save(List<WaitlistEntry> entries, int nextTicketNumber) async {
    this.entries = List.of(entries);
    this.nextTicketNumber = nextTicketNumber;
  }
 
  test('does not publish a party when persistence fails', () async {
    final repository = FailingWaitlistRepository();
    final controller = WaitlistController(repository);
    await controller.load();

    expect(
      await controller.addParty(name: 'Alice', partySize: 2),
      isFalse,
    );
    expect(controller.entries, isEmpty);
  });

  test('queue order determines parties ahead, not party size', () async {
    final repository = FakeWaitlistRepository();
    final controller = WaitlistController(repository);
    await controller.load();

    await controller.addParty(name: 'Large party', partySize: 10);
    await controller.addParty(name: 'Small party', partySize: 1);
    await controller.addParty(name: 'Another party', partySize: 2);

    expect(controller.entries.map((entry) => entry.name), [
      'Large party',
      'Small party',
      'Another party',
    ]);

    expect(controller.entries[0].partiesAheadOf(0), 0);
    expect(controller.entries[1].partiesAheadOf(1), 1);
    expect(controller.entries[2].partiesAheadOf(2), 2);
  });
}





class FailingWaitlistRepository extends FakeWaitlistRepository {
  @override
  Future<void> save(List<WaitlistEntry> entries, int nextTicketNumber) async {
    throw StateError('storage unavailable');
  }
}

void main() {
  test('adds parties in order and assigns unique tickets', () async {
    final repository = FakeWaitlistRepository();
    final controller = WaitlistController(repository);
    await controller.load();

    expect(await controller.addParty(name: 'Alice', partySize: 2), isTrue);
    expect(await controller.addParty(name: 'Bob', partySize: 4), isTrue);

    expect(controller.entries.map((e) => e.ticketNumber), [1, 2]);
    expect(controller.entries.map((e) => e.name), ['Alice', 'Bob']);
  });

  test('rejects invalid parties', () async {
    final repository = FakeWaitlistRepository();
    final controller = WaitlistController(repository);
    await controller.load();

    expect(await controller.addParty(name: '   ', partySize: 2), isFalse);
    expect(await controller.addParty(name: 'Alice', partySize: 0), isFalse);
    expect(controller.entries, isEmpty);
  });

  test('removal updates parties ahead without reusing tickets', () async {
    final repository = FakeWaitlistRepository();
    final controller = WaitlistController(repository);
    await controller.load();

    await controller.addParty(name: 'Alice', partySize: 2);
    await controller.addParty(name: 'Bob', partySize: 2);
    await controller.addParty(name: 'Cara', partySize: 2);

    await controller.removeParty(2);
    expect(controller.entries.map((e) => e.ticketNumber), [1, 3]);

    expect(await controller.addParty(name: 'Dan', partySize: 1), isTrue);
    expect(controller.entries.map((e) => e.ticketNumber), [1, 3, 4]);
  });

  test('restores state and continues ticket numbering', () async {
    final repository = FakeWaitlistRepository();
    final first = WaitlistController(repository);
    await first.load();
    await first.addParty(name: 'Alice', partySize: 2);
    await first.addParty(name: 'Bob', partySize: 2);
    await first.removeParty(1);

    final reopened = WaitlistController(repository);
    await reopened.load();

    expect(reopened.entries.map((e) => e.ticketNumber), [2]);
    expect(await reopened.addParty(name: 'Cara', partySize: 3), isTrue);
    expect(reopened.entries.last.ticketNumber, 3);
  });
}
