# Architecture

## 1. Project Overview

Restaurant Waitlist is a staff-facing Flutter application for managing a restaurant's waiting queue on a single device.

The MVP solves four practical problems:

- Staff can add a party with a name and positive whole-number party size.
- Each party receives a unique, increasing ticket number and is appended to the FIFO waitlist.
- Staff can see the queue order and how many waiting parties are ahead of each party, and can remove a party.
- The queue and the next ticket number survive a complete app restart, so removed tickets are never reused.

The implementation also includes the optional **undo last removal** behavior, plus loading, empty, validation, persistence-error, and retry states. Other optional features such as editing, history, and estimated wait times are intentionally excluded.

There is no backend, authentication, customer-facing app, notifications, multi-branch support, or server API.

---

## 2. Architecture Approach

The project uses a small **feature-first architecture** with explicit separation between presentation, application/state management, domain contracts/entities, and persistence.

The effective dependency direction is:

```text
Presentation
    ↓
Application / State
    ↓
Domain Repository Contract
    ↓
Data Repository
    ↓
SharedPreferences
```

The main implementation is contained inside `features/waitlist`. This keeps the feature's code together while still separating responsibilities.

### Presentation

`WaitlistPage` owns the Flutter UI: displaying the queue, collecting input, showing validation and loading/error states, and triggering actions.

It does not know how waitlist data is persisted.

### Application / Business Logic

`WaitlistController` extends Flutter's `ChangeNotifier` and is the state owner for the waitlist.

It handles:

- validation used by the UI and add operation;
- ticket allocation;
- queue ordering;
- parties-ahead calculation through queue position;
- add/remove/undo operations;
- mutation serialization;
- loading and error state;
- publishing state changes only after persistence succeeds.

This is intentionally a single application-level state owner because the MVP has one main screen and one queue.

### Domain

`WaitlistEntry` represents the core waitlist entity.

`WaitlistRepository` is an abstract repository contract. The application layer depends on this contract rather than directly depending on SharedPreferences.

This is a lightweight form of dependency inversion without introducing a full use-case framework.

### Data

`SharedPreferencesWaitlistRepository` implements the repository contract and is the only layer that knows the persistence format and SharedPreferences API.

The queue and the next ticket number are stored together as one JSON state value. The repository validates the persisted structure when loading it.

### APIs / External Services

There is intentionally no network API or external service. The assessment requires on-device persistence only, so adding a network layer would create unnecessary complexity.

### Why this architecture?

The architecture is deliberately smaller than a full Clean Architecture template.

A separate router, dependency-injection framework, network layer, use-case class for every operation, and generic core abstraction would not provide meaningful value for one screen and one local data source within a 2.5-hour assessment.

The repository abstraction is the important boundary: it keeps persistence replaceable and prevents UI code from becoming coupled to storage.

---

## 3. Project Structure

### Flutter root structure

Important root directories/files are:

```text
project/
├── android/                         # Android platform project
├── lib/                             # Application source
├── test/                            # Automated tests
│   ├── unit/
│   └── widget_test.dart
├── pubspec.yaml                     # Dependencies and package configuration
├── pubspec.lock                     # Resolved dependency versions
├── analysis_options.yaml            # Dart/Flutter analysis rules
├── .gitignore
├── README.md                        # Run instructions and project summary
├── CHANGELOG.md                     # Project change history
├── prompt.md                        # Assessment prompt history
└── ARCHITECTURE.md                  # This engineering documentation
```

The submitted project targets Android, which is the supported platform for the assessment. Standard platform/configuration files are preserved rather than replaced with custom tooling.

There are no application-specific assets, backend configuration, or platform-independent service folders because the current MVP does not require them.

### `lib/` structure

```text
lib/
├── main.dart
├── app/
│   └── app.dart
└── features/
    └── waitlist/
        ├── application/
        │   └── waitlist_controller.dart
        ├── data/
        │   └── repositories/
        │       └── shared_preferences_waitlist_repository.dart
        ├── domain/
        │   ├── entities/
        │   │   └── waitlist_entry.dart
        │   └── repositories/
        │       └── waitlist_repository.dart
        └── presentation/
            └── pages/
                └── waitlist_page.dart
```

#### `main.dart`

The composition root. It initializes Flutter, obtains SharedPreferences, constructs the repository and controller, loads persisted state, and starts the application.

#### `app/app.dart`

Defines the application shell, Material theme, and initial page. It does not contain waitlist business rules.

#### `features/waitlist/application/`

Contains the stateful application logic for the waitlist.

#### `features/waitlist/domain/entities/`

Contains the waitlist entity independent of Flutter widgets and persistence implementation.

#### `features/waitlist/domain/repositories/`

Contains the repository abstraction consumed by application logic.

#### `features/waitlist/data/repositories/`

Contains the concrete SharedPreferences persistence implementation and serialization/deserialization validation.

#### `features/waitlist/presentation/`

Contains the screen and presentation-specific widgets/state interaction.

This structure was chosen to make the boundaries visible without creating empty or speculative architectural layers.

---

## 4. Feature Organization

The project has one business feature: `waitlist`.

All waitlist-specific application, domain, data, and presentation code lives under:

```text
lib/features/waitlist/
```

Feature-first organization was selected because the project is expected to grow by business capability rather than by technical layer alone.

For example, a future feature could be introduced as:

```text
features/
├── waitlist/
└── history/
```

Each feature could own its presentation, state, domain contracts, and data implementation. This reduces the chance that adding a feature requires modifying unrelated waitlist code.

The current project does not create additional feature folders because there is no implemented second business feature.

---

## 5. Data Flow

A typical **add party** operation follows this path:

```text
Staff enters name + party size
          │
          ▼
WaitlistPage
  validates form input
          │
          ▼
WaitlistController.addParty()
  validates again
  assigns next ticket
  creates updated queue
          │
          ▼
WaitlistRepository.save()
          │
          ▼
SharedPreferencesWaitlistRepository
  serializes queue + next ticket
          │
          ▼
SharedPreferences
          │
          ▼
save succeeds
          │
          ▼
Controller publishes new state
          │
          ▼
WaitlistPage rebuilds
```

The important consistency decision is that the controller does **not** publish the new queue before persistence succeeds.

For removal:

```text
Remove action
    ↓
WaitlistController.removeParty(ticket)
    ↓
Create updated queue
    ↓
Repository.save(updated queue, existing next ticket)
    ↓
Persistence succeeds
    ↓
Controller publishes updated queue
    ↓
UI recalculates parties-ahead from list position
```

For loading:

```text
main.dart
   ↓
controller.load()
   ↓
repository.loadEntries()
repository.loadNextTicketNumber()
   ↓
SharedPreferences
   ↓
controller state
   ↓
WaitlistPage
```

There is no API interaction in the current application.

---

## 6. State Management

The application uses Flutter's built-in **`ChangeNotifier`**.

`WaitlistController` is the single state owner and exposes immutable views of its entry list.

Relevant state includes:

- `entries`
- `isLoading`
- `isMutating`
- `hasLoadError`
- `errorMessage`
- `lastRemoval`
- the internal next ticket number

`WaitlistPage` listens with `AnimatedBuilder`, so a state change triggers the UI to rebuild.

### Why ChangeNotifier?

For this MVP it provides:

- no additional state-management dependency;
- a familiar Flutter pattern;
- explicit state ownership;
- straightforward loading/error/mutation transitions;
- enough capability for one screen and one state owner.

A larger application with many independently changing feature states could benefit from a more structured state-management solution, but adding one here would increase dependency and conceptual overhead without solving a current problem.

### Mutation consistency

The controller uses `_isMutating` to prevent overlapping add/remove/undo operations.

The UI also disables mutation controls while persistence is in flight.

This avoids concurrent operations calculating from stale queue state and reduces the chance of conflicting writes.

---

## 7. Dependency Management

The project intentionally has very few runtime dependencies.

### Flutter

The Flutter SDK provides the application framework, Material UI, widgets, and `ChangeNotifier`.

### shared_preferences

`shared_preferences` provides simple on-device key-value persistence.

It was chosen because the MVP stores one small serialized queue and one integer counter. There are no relational queries, joins, complex transactions, or large datasets.

### flutter_test

The Flutter testing framework is used for unit and widget tests.

### flutter_lints

Flutter's recommended lint package is used for static analysis and consistent Dart style.

No routing, dependency-injection, networking, database ORM, or external state-management package is currently justified.

---

## 8. Error Handling

The application treats expected persistence and input failures as application states rather than allowing them to crash the UI.

### Input errors

The UI validates:

- non-empty name;
- whole-number party size;
- party size greater than zero.

The controller also validates the same business constraints before mutating state, so the rule is not dependent only on presentation validation.

### Persistence errors

Repository failures are caught by the controller.

For example, if saving a new party fails:

1. the controller does not publish the new entry;
2. an error message is exposed;
3. mutation state is cleared;
4. the UI remains usable and reports the failure.

The same pattern is used for removal and undo.

### Load errors

If persisted data cannot be loaded or validated, the controller exposes a load-error state and the screen shows a retry action.

### Corrupt persisted data

The repository validates:

- JSON structure;
- entry types;
- ticket numbers;
- party sizes;
- non-empty names;
- duplicate ticket numbers;
- next ticket number validity.

The controller also protects the ticket invariant by ensuring a loaded next ticket number is greater than the maximum existing ticket.

This is intentionally defensive because persisted state is an external boundary from the controller's perspective.

---

## 9. Scalability

The current architecture is intentionally sized for the MVP but has useful extension points.

### Replacing storage

The application depends on `WaitlistRepository`, not SharedPreferences.

A future implementation could therefore provide:

```text
WaitlistRepository
├── SharedPreferencesWaitlistRepository
├── SqliteWaitlistRepository
└── RemoteWaitlistRepository
```

without changing the UI contract.

A production database would be preferable if the requirements expanded to include large histories, richer queries, multiple entities, or stronger transactional guarantees.

### Adding features

A future business feature can receive its own feature module rather than placing unrelated logic into `waitlist`.

For example:

```text
features/
├── waitlist/
├── history/
└── table_management/
```

### Adding screens

New screens can be added under the relevant feature's presentation layer. Routing was deliberately not introduced because the current MVP has a single screen.

### Adding backend/API support

A remote repository can implement the existing repository abstraction, although production synchronization would require additional concerns such as connectivity, conflict resolution, authentication, and retry policies. Those are intentionally outside this assessment.

### Deliberate MVP trade-offs

The project does not introduce:

- a full dependency-injection framework;
- a generic use-case layer;
- a networking abstraction;
- a database ORM;
- a global design system;
- a routing package;
- multiple feature modules;
- a backend.

These could be useful at production scale, but they would add complexity without improving the assessed one-screen MVP.

---

## 10. Testing Strategy

Testing prioritizes the business rules and state transitions that could cause an incorrect assessment result.

### Unit tests

The controller tests cover important business behavior such as:

- adding parties in queue order;
- unique/increasing ticket numbers;
- invalid input rejection;
- parties-ahead semantics based on queue position;
- removal without ticket reuse;
- restoration after reopening;
- stale counter recovery;
- persistence failure without publishing invalid state;
- failed removal behavior;
- undo behavior.

Repository tests cover persistence serialization/deserialization and invalid stored data.

### Widget tests

Widget tests cover important user-facing flows and states, including:

- adding a party through the UI;
- validation feedback;
- load errors and retry;
- persistence failure feedback;
- removal and undo;
- layout resilience under constrained/enlarged display conditions.

### Integration tests

There is currently no separate integration-test suite. The highest-value MVP behavior is covered by unit and widget tests, while full process restart on a real emulator remains an important manual verification step.

### Why these tests were prioritized

The assessment gives the highest weight to correctness of the core criteria and the three queue rules.

Therefore, tests focus on:

1. ticket uniqueness/persistence;
2. FIFO ordering and parties-ahead behavior;
3. persistence failure behavior;
4. user flows that exercise those rules.

Testing every visual detail or every possible device configuration would provide less value within the assessment time limit.

---

## 11. Security & Maintainability

There are no user accounts, authentication credentials, backend secrets, API keys, or sensitive network configuration in this MVP.

The waitlist data is local application state. It is not intended to be a secure record system or shared server-side database.

### Maintainability decisions

The implementation uses several boundaries that are directly useful:

- UI is separated from persistence.
- Business/state logic is kept in `WaitlistController`.
- Persistence is behind `WaitlistRepository`.
- The waitlist entity does not depend on Flutter widgets.
- Input and persisted-data validation protect core invariants.
- Mutations are persisted before the new state is published.
- The entry list exposed to presentation is unmodifiable.
- The feature owns its business-specific code.

There are intentionally no abstractions whose only purpose is to make the architecture look more elaborate.

---

## 12. Engineering Decisions & Trade-offs

| Decision | Reason | Alternative considered | Trade-off |
|---|---|---|---|
| Flutter | Fast cross-platform development while targeting the required mobile emulator | Native Android | Flutter adds an SDK/runtime abstraction but provides efficient development and a clear widget/test ecosystem |
| Android as the submission platform | The assessment requires only one platform | Android + iOS | Limits platform coverage, but avoids spending assessment time on an unnecessary second target |
| Feature-first organization | Keeps the waitlist capability cohesive and supports future features | Layer-first global folders | Slightly more nesting for a single feature, but scales better as business features grow |
| `ChangeNotifier` | Simple built-in state management for one screen | Riverpod/BLoC/etc. | Less sophisticated for a large application, but avoids an unnecessary dependency and learning surface |
| Repository interface | Separates business/state logic from persistence | Direct SharedPreferences calls from controller | Adds one interface and adapter, but makes the data source replaceable and testable |
| SharedPreferences + JSON | The queue is small and needs simple local persistence | SQLite/Drift/Hive | Less suitable for complex queries/history at scale, but substantially faster and simpler for this MVP |
| Store queue and next ticket together | Keeps persisted queue state and ticket sequence consistent | Separate storage keys | One serialized state is simple to reason about; a database would provide stronger transactional semantics at larger scale |
| Persist before publishing state | Prevents UI state from claiming a mutation succeeded when storage failed | Optimistic UI update | Slightly less responsive during storage writes, but gives stronger correctness guarantees |
| Reject overlapping mutations | Prevents concurrent operations from using stale queue state | Queue mutation commands | Simpler and sufficient for one staff member/device; a larger system may need a command queue |
| Controller-level validation | Protects business rules independently of UI validation | UI-only validation | Some validation is duplicated at the presentation boundary, but the domain-facing mutation remains safe |
| Defensive persisted-state validation | Local storage is still an external boundary and corrupted/incompatible data should not silently become invalid state | Trust stored JSON | More code in the repository, but protects ticket and queue invariants |
| No generic use-case layer | There is one small feature and the controller operations are already cohesive | One class per use case | Less indirection and fewer files for the assessment |
| No routing/DI framework | There is one screen and a small composition root | GoRouter/GetIt/etc. | Requires a little manual wiring if the app grows, but avoids premature infrastructure |
| High-value unit/widget testing | Assessment prioritizes correctness and engineering reasoning | Broad end-to-end test suite | Less exhaustive device coverage, but better value within the time constraint |
| Optional undo removal included | It is small and improves staff usability without changing the core model | Exclude all optional features | Adds state and tests, but remains contained in the controller and UI |
| History/editing/estimated wait excluded | Explicitly optional and not needed for the core score | Implement all extras | More features would increase risk and reduce time for verification |

---

## 13. Future Improvements

### Intentionally excluded MVP functionality

These are not implemented and should not be represented as completed:

- editing a waiting party;
- removal history screen;
- estimated waiting times;
- backend/server synchronization;
- accounts/authentication;
- notifications;
- multi-branch support;
- iOS support in the submitted workflow.

Undoing the most recent removal is implemented.

### If more development time were available

The next improvements would be:

1. Add a real local database if history and richer queries become requirements.
2. Add a dedicated persistence/data-source abstraction if multiple storage mechanisms are introduced.
3. Add routing when multiple screens exist.
4. Consider a more structured state-management solution when state becomes distributed across several features.
5. Add integration tests covering real application restart and persistence on an emulator.
6. Add accessibility review and broader device-size testing.
7. Add structured domain/application error types instead of user-facing strings where the application grows.
8. Add migration/versioning for persisted data before changing the storage schema in production.
9. Add observability/logging appropriate for production failures.
10. If synchronization becomes necessary, introduce a backend repository with explicit offline, retry, and conflict-resolution behavior.

These are production-scale improvements rather than requirements that need to be added to the current assessment MVP.

---

## Verification Notes

This document was written against the current repository implementation. The current README records successful `flutter analyze`, `flutter test`, and `flutter build apk --debug` checks, including 22 automated tests, plus an Android emulator launch during implementation.

No application-code changes are required to create this document.
