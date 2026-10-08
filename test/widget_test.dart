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
  bool failSaves = false;

  @override
  Future<List<WaitlistEntry>> loadEntries() async {
    if (failLoads) throw StateError('storage unavailable');
    return List.of(entries);
  }

  @override
  Future<int> loadNextTicketNumber() async => nextTicketNumber;

  @override
  Future<void> save(List<WaitlistEntry> entries, int nextTicketNumber) async {
    if (failSaves) throw StateError('storage unavailable');
    this.entries = List.of(entries);
    this.nextTicketNumber = nextTicketNumber;
  }
}

Future<WaitlistController> _pumpWaitlist(WidgetTester tester) async {
  final controller = WaitlistController(_MemoryWaitlistRepository());
  await controller.load();
  await tester.pumpWidget(RestaurantWaitlistApp(controller: controller));
  return controller;
}

void main() {
  testWidgets('empty state explains there are no waiting parties',
      (tester) async {
    final controller = await _pumpWaitlist(tester);

    expect(find.text('No parties waiting'), findsOneWidget);
    expect(find.text('Add a party to start the queue.'), findsOneWidget);
    expect(find.byIcon(Icons.groups_outlined), findsOneWidget);

    controller.dispose();
  });

  testWidgets('adding parties shows tickets and correct parties ahead',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = await _pumpWaitlist(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Alice');
    await tester.enterText(find.byType(TextField).at(1), '2');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(CircleAvatar).first).label,
      startsWith('Ticket number 1'),
    );
    expect(find.text('Party of 2 - Next up'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Bob');
    await tester.enterText(find.byType(TextField).at(1), '3');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(CircleAvatar).last).label,
      startsWith('Ticket number 2'),
    );
    expect(find.text('Party of 3 - 1 ahead'), findsOneWidget);

    semantics.dispose();
    controller.dispose();
  });

  testWidgets('empty-name validation is shown inline', (tester) async {
    final controller = await _pumpWaitlist(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pump();

    expect(find.text('Name is required.'), findsOneWidget);
    expect(find.text('Enter a whole number greater than 0.'), findsNothing);
    expect(controller.entries, isEmpty);

    controller.dispose();
  });

  testWidgets('load error can be retried and then enables adding',
      (tester) async {
    final repository = _MemoryWaitlistRepository()..failLoads = true;
    final controller = WaitlistController(repository);
    await controller.load();
    await tester.pumpWidget(RestaurantWaitlistApp(controller: controller));

    expect(find.text('Could not load the saved waitlist.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Add'))
          .onPressed,
      isNull,
    );

    repository.failLoads = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(controller.errorMessage, isNull);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Add'))
          .onPressed,
      isNotNull,
    );
    controller.dispose();
  });

  testWidgets('persistence failure shows an error without adding a party',
      (tester) async {
    final repository = _MemoryWaitlistRepository()..failSaves = true;
    final controller = WaitlistController(repository);
    await controller.load();
    await tester.pumpWidget(RestaurantWaitlistApp(controller: controller));

    await tester.enterText(find.byType(TextField).at(0), 'Alice');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(controller.entries, isEmpty);
    expect(find.text('Could not save the new party.'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('removal snackbar undo restores the party', (tester) async {
    final controller = await _pumpWaitlist(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Alice');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove Alice'));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsNothing);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(controller.entries.single.ticketNumber, 1);
    controller.dispose();
  });

  testWidgets('queue and form fit a short screen with enlarged text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = WaitlistController(_MemoryWaitlistRepository());
    await controller.load();
    await controller.addParty(name: 'Alice', partySize: 2);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: RestaurantWaitlistApp(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Waitlist'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    tester.view.physicalSize = const Size(640, 360);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
