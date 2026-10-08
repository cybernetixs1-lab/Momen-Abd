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

- Complete: add validated parties, assign unique increasing tickets, show FIFO order and parties ahead, remove parties, persist the queue and next ticket number, and undo the latest removal for five seconds.
- Also covered: loading, empty, persistence-error and retry states; saving changes only after storage succeeds; rejecting overlapping mutations; inline form validation.
- Not implemented: edit, removal history, estimated waiting times, backend, accounts, notifications, and iOS support.
- Automated checks: `flutter analyze` passed with no issues; `flutter test` passed all 22 tests; `flutter build apk --debug` passed. The app was launched on an Android 16 emulator during implementation.

One AI suggestion was to keep persistence behind a repository and use local key-value storage. I checked it against the requirements (small on-device state, no queries or relationships) and added a persistence test that restores both the queue and next ticket number, including after the queue is emptied.

## Trade-offs and next steps

- SharedPreferences is sufficient for this small single-device queue; use a database if history or richer queries are added.
- The controller serializes changes by rejecting a second mutation while a save is in flight; the UI disables mutation controls during that save.
- Automated widget coverage includes short, large-text and landscape layouts, but device rotation and process-restart behavior should still be checked manually.
- Optional history, editing and estimated wait times were excluded to keep the MVP focused.

## Screenshots

_Placeholder: add emulator screenshots before submission._
