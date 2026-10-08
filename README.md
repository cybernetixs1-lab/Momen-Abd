# Restaurant Waitlist

A small Flutter app for restaurant staff to manage a first-in, first-out waitlist.

## Run on an Android emulator

Prerequisites: Flutter SDK and Android tooling installed, plus an Android emulator.

1. Clone this repository.
2. Run `flutter pub get`.
3. Start an Android emulator.
4. Run `flutter run` from the repository root.

No code changes or backend configuration are required.

## Technology and storage

I chose Flutter because it provides a fast, cross-platform UI while keeping the MVP small and easy to run on Android. I chose `shared_preferences` because this app stores a small amount of local, non-relational state and does not need a queryable database.

## Architecture

- **domain**: waitlist model and repository contract.
- **data**: local SharedPreferences implementation.
- **application**: controller containing validation and business rules.
- **presentation**: Flutter widgets in `lib/main.dart` for this intentionally small MVP.

The repository abstraction keeps storage replaceable if the app later grows to require SQLite/Drift or another persistence layer.

## Complete

- Add a party with a non-empty name and positive whole-number size.
- Assign a unique, never-reused ticket number.
- Append parties in arrival order.
- Show how many waiting parties are ahead.
- Remove any party and immediately recalculate positions.
- Persist the active waitlist and next ticket number across app restarts.
- Unit tests cover the core business rules.

## Not included

Optional extras (editing, undo, history, estimated wait time) are intentionally not included because the core requirements take priority.

## Verification / AI suggestion check

AI suggested using a local key-value store and separating persistence behind a repository interface. I checked that decision against the requirements: the data set is small, there are no queries or relationships, and only the current list plus the next ticket counter must survive restarts, so SharedPreferences is sufficient for this MVP.

I also checked the ticket rule manually: add tickets 1, 2, 3; remove 2; add another party; the new ticket must be 4 and the remaining list must be 1, 3, 4.

## Notes

There is intentionally no backend, authentication, customer app, notification system, or multi-branch support because those are out of scope.
