import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_waitlist/features/waitlist/data/repositories/shared_preferences_waitlist_repository.dart';
import 'package:restaurant_waitlist/features/waitlist/domain/entities/waitlist_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores queue and ticket counter, including when the queue is empty',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesWaitlistRepository(preferences);
    const entry = WaitlistEntry(
      ticketNumber: 1,
      name: 'Alice',
      partySize: 2,
    );

    await repository.save([entry], 2);

    final restored = SharedPreferencesWaitlistRepository(
        await SharedPreferences.getInstance());
    final restoredEntries = await restored.loadEntries();
    expect(restoredEntries, hasLength(1));
    expect(restoredEntries.single.ticketNumber, 1);
    expect(restoredEntries.single.name, 'Alice');
    expect(restoredEntries.single.partySize, 2);
    expect(await restored.loadNextTicketNumber(), 2);

    await restored.save([], 2);

    final emptyRestore = SharedPreferencesWaitlistRepository(
        await SharedPreferences.getInstance());
    expect(await emptyRestore.loadEntries(), isEmpty);
    expect(await emptyRestore.loadNextTicketNumber(), 2);
  });
}
