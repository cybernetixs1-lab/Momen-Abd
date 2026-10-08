import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_waitlist/app/app.dart';
import 'package:restaurant_waitlist/features/waitlist/application/waitlist_controller.dart';
import 'package:restaurant_waitlist/features/waitlist/domain/entities/waitlist_entry.dart';
import 'package:restaurant_waitlist/features/waitlist/domain/repositories/waitlist_repository.dart';

class _MemoryWaitlistRepository implements WaitlistRepository {
  List<WaitlistEntry> entries = [];
  int nextTicketNumber = 1;
  bool failLoads = false;

  @override
  Future<List<WaitlistEntry>> loadEntries() async {
    if (failLoads) throw StateError('storage unavailable');
    return List.of(entries);
  }

  @override
  Future<int> loadNextTicketNumber() async => nextTicketNumber;

  @override
  Future<void> save(List<WaitlistEntry> entries, int nextTicketNumber) async {
    this.entries = List.of(entries);
    this.nextTicketNumber = nextTicketNumber;
  }
}

void main() {
  testWidgets('staff can add, remove, and continue ticket numbering',
      (tester) async {
    final controller = WaitlistController(_MemoryWaitlistRepository());
    await controller.load();
    await tester.pumpWidget(RestaurantWaitlistApp(controller: controller));

    await tester.tap(find.text('Add party'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Alice');
    await tester.enterText(find.byType(TextFormField).at(1), '2');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('Add party'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Bob');
    await tester.enterText(find.byType(TextFormField).at(1), '3');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.textContaining('0 parties ahead'), findsOneWidget);
    expect(find.textContaining('1 party ahead'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsNothing);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.textContaining('0 parties ahead'), findsOneWidget);

    await tester.tap(find.text('Add party'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Cara');
    await tester.enterText(find.byType(TextFormField).at(1), '1');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Cara'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('enables adding after a failed initial load is retried',
      (tester) async {
    final repository = _MemoryWaitlistRepository()..failLoads = true;
    final controller = WaitlistController(repository);
    await controller.load();
    await tester.pumpWidget(RestaurantWaitlistApp(controller: controller));

    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .onPressed,
      isNull,
    );

    repository.failLoads = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(controller.errorMessage, isNull);
    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .onPressed,
      isNotNull,
    );
    controller.dispose();
  });
}
