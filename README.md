# Restaurant Waitlist

A staff-facing Flutter app for managing a first-in, first-out restaurant waitlist.

## Run on Android

Prerequisites: Flutter SDK, Android Studio with the Android SDK, and an Android emulator.

1. Run `flutter pub get` from the repository root.
2. List available emulators with `flutter emulators`, then launch one with `flutter emulators --launch <emulator_id>`. Alternatively, start an emulator from Android Studio's Device Manager.
3. Run `flutter run` from the repository root.

## Implementation

Flutter was chosen for fast development of the required Android mobile app. SharedPreferences stores the small, local waitlist state without needing database queries or relationships.

The feature-first implementation keeps the screen, queue state and rules, repository contract, and persistence adapter separate:

```text
WaitlistPage → WaitlistController → WaitlistRepository → SharedPreferences
```

The controller assigns increasing ticket numbers, validates additions, and publishes mutations only after persistence succeeds. The repository stores the queue and next ticket number together, so removing the last party does not reset ticket numbering. A database would be more appropriate if the app needed history or complex queries; a router, DI framework, and separate use-case layer are omitted because the MVP has one screen and one state owner.

## Status and checks

- Complete: add and validate parties, assign non-reused ticket numbers, display arrival order and parties ahead, remove any party, persist queue/counter, and show loading, empty, and persistence-error states.
- Not implemented: optional edit, undo, history, estimated wait times, backend, accounts, and notifications.
- Automated checks: `flutter analyze`, `flutter test`, and `flutter build apk --debug`.

One AI suggestion was to keep persistence behind a repository and use local key-value storage. I checked it against the requirements (small on-device state, no queries or relationships) and added a persistence test that restores both the queue and next ticket number, including after the queue is emptied.

With more time, I would test the full Android restart flow on a device, add stronger persistence error reporting, and move to a queryable database if waitlist history or reporting were required.
