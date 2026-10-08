# Restaurant Waitlist

A small Flutter app for restaurant staff to manage a first-in, first-out waitlist.

## Run on an Android emulator

Prerequisites: Flutter SDK, Android tooling, and an Android emulator.

1. Clone this repository.
2. Run `flutter pub get`.
3. Start an Android emulator.
4. Run `flutter run` from the repository root.

For a clean checkout, the repository should contain the generated Flutter Android project files; no application-code changes or backend configuration are required.

## Technology and storage

I chose Flutter because it gives a small, cross-platform codebase while being quick to develop and run on an Android emulator. I chose SharedPreferences because the MVP stores a small amount of local, non-relational state and does not need queries, relationships, or a backend.

## Architecture

```
presentation -> application -> domain <- data
```

- **domain**: waitlist entity and repository contract.
- **data**: SharedPreferences implementation and JSON serialization.
- **application**: controller containing validation, ticket numbering, persistence sequencing, and mutation rules.
- **presentation**: Flutter widgets that render controller state and collect staff input.

The repository abstraction keeps storage replaceable if the app later grows to need a queryable local database. No state-management package is used because a single `ChangeNotifier` is sufficient for this small state surface.

## Complete

- Add a party with a non-empty name and positive whole-number size.
- Assign a unique ticket number that is never reused.
- Append parties in arrival order.
- Show the number of waiting parties ahead.
- Remove any waiting party and immediately recalculate positions.
- Persist the active waitlist and next ticket number across app restarts.
- Handle persistence failures without publishing an unpersisted state change.
- Unit tests cover the core business rules and failure paths.

## Not included

The optional extras—editing, undo, removal history, and estimated waiting time—are intentionally not included because the core requirements take priority within the time limit.

Backend services, accounts, customer-facing features, notifications, multi-branch support, and app-store publishing are also out of scope.

## Verification

The important manual cases are:

1. Add three parties and verify tickets `1, 2, 3` and positions `0, 1, 2`.
2. Remove ticket `2`; verify the remaining tickets are `1, 3` and the second remaining party has one party ahead.
3. Add another party; verify it receives ticket `4`, not `2`.
4. Fully close and reopen the app; verify the active queue remains and the next ticket continues.
5. Try an empty name, zero/negative size, and non-integer size; each must be rejected.

## AI suggestion check

AI suggested using a local key-value store and separating persistence behind a repository interface. I checked that suggestion against the requirements: the data is small, there are no queries or relationships, and only the current queue plus the next ticket counter must survive restarts, so SharedPreferences is appropriate for this MVP.

I also checked the ticket-numbering suggestion manually with tickets `1, 2, 3`: after removing `2`, adding a new party must produce `4`, proving removed tickets are never reused.
