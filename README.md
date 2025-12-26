# rmutl-fullProject

Flutter app with Firebase backend for student, teacher, and admin roles. Includes role-based home screens, chat, notifications, forum posts, and academic reporting calculated by Cloud Functions.

## Features
- Role-based navigation for Student, Teacher, Admin
- User management and profile editing
- Forum posts with teacher announcements
- Notifications with unread indicator
- Chat with recent conversations and search
- Academic report calculation stored under each user

## Tech Stack
- Flutter (Dart)
- Firebase Auth, Firestore, Storage, Functions
- go_router
- fl_chart

## Project Structure (high level)
- `lib/` Flutter app
  - `ui/` screens by role
  - `services/` data/services layer
  - `models/` app models
  - `widgets/` shared widgets
- `functions/` Firebase Cloud Functions (Node 22)
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` platform folders

## Firebase
Default project: `rmutl-fullproject` (see `.firebaserc`)

Cloud Functions (see `functions/`):
- `sendOtpEmail` (HTTPS)
- `calculateStudentMetrics` (HTTPS)
- `recalculateStudentMetricsOnEnrollmentChange` (Firestore trigger)
- `recalculateAllMetrics` (HTTPS)

## Setup
1. Install Flutter SDK and run `flutter doctor`.
2. Install Node.js 22 and Firebase CLI (`npm i -g firebase-tools`).
3. Fetch dependencies:
   - `flutter pub get`
   - `cd functions && npm install`
4. Ensure Firebase config files exist:
   - `android/app/google-services.json`
   - `lib/firebase_options.dart`

## Run (Flutter)
- Android: `flutter run`
- Web: `flutter run -d chrome`

## Functions
From `functions/`:
- Deploy: `firebase deploy --only functions`
- Emulator: `firebase emulators:start --only functions`

## Notes
- Reports are stored at `user/{userDocId}/app/report`.
- Notifications are stored per-user under `user/{userDocId}/notifications`.
