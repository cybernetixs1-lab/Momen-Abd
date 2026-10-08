# Restaurant Waitlist

A small Flutter app for restaurant staff to manage a first-in, first-out waitlist.

## Run

Prerequisites: Flutter SDK, Android tooling, and an Android emulator.

1. Clone this repository.
2. Run `flutter pub get`.
3. Start an Android emulator.
4. Run `flutter run` from the repository root.

The assessment targets Android. The repository is intentionally kept to the platform required by the MVP; desktop platforms are not included.

## Architecture

The app uses a practical feature-first structure without creating layers that the MVP does not need:

```
lib/
├── app/
│   └── app.dart
├── features/
│   └── waitlist/
│       ├── application/
│       │   └── waitlist_controller.dart
│       ├── data/
│       │   └── repositories/
│       │       └── shared_preferences_waitlist_repository.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── waitlist_entry.dart
│       │   └── repositories/
│       │       └── waitlist_repository.dart
│       └── presentation/
│           └── pages/
│               └── waitlist_page.dart
└── main.dart
```

### Data flow

```
Presentation
    ↓
WaitlistController
    ↓
WaitlistRepository
    ↓
SharedPreferences
```

The UI does not know about persistence details. The controller owns queue business rules and state, while the repository abstraction keeps the storage implementation replaceable.

### Why this architecture

Flutter was chosen because it is fast to develop and suitable for the required Android emulator. SharedPreferences was chosen because the MVP has a small amount of local, non-relational state and does not require queries or relationships.

The repository boundary allows a future database or API implementation without coupling the presentation layer to storage. A separate router, dependency-injection framework, use-case layer, network layer, or global state-management package was intentionally not added because the MVP has one screen and one state owner.

## Core functionality

- Add a party with a non-empty name and positive whole-number size.
- Assign a unique ticket number that is never reused.
- Keep parties in arrival order.
- Show how many waiting parties are ahead.
- Remove any waiting party.
- Persist the active waitlist and next ticket number across restarts.
- Handle persistence failures without publishing an unpersisted mutation.

## Testing and verification

Unit tests cover the core controller rules, ticket continuity, removal behavior, persistence failure paths, and stale-counter recovery.

Important manual checks:

1. Add three parties and verify tickets `1, 2, 3` and positions `0, 1, 2`.
2. Remove ticket `2`; verify the remaining tickets are `1, 3`.
3. Add another party; verify it receives ticket `4`.
4. Completely close and reopen the app; verify the queue remains and the next ticket continues.
5. Try an empty name, zero/negative size, and non-integer size; each must be rejected.

## Complete

The required MVP is implemented. Optional extras—edit, undo, history, and estimated waiting time—are intentionally excluded.

## AI suggestion verification

AI suggested separating persistence behind a repository and using local key-value storage. I checked that against the requirements: the MVP only needs a small queue and ticket counter, with no relationships or queries, so SharedPreferences is appropriate and the repository abstraction keeps the storage replaceable.

## Production improvements

With more time, I would add stronger widget/integration coverage, a queryable local database if the queue/history grew substantially, richer error types, and a more formal dependency-injection boundary if the application gained multiple features or data sources.
