# RMUTL Full Project - AI Coding Agent Instructions

## Project Overview
Full-stack Flutter + Firebase application for RMUTL (educational institution) with role-based access control (Admin, Teacher, Student). Includes forums, grade management, career tracking, and admin configuration dashboards.

## Architecture & Key Components

### Frontend: Flutter App (`lib/`)
- **Router**: `app_router.dart` — GoRouter-based navigation with role-aware routing and shell routes for each user role
- **UI Structure**: `ui/{admin,teacher,student,common,auth,forum}/` — Organized by role and feature
- **Services** (`lib/services/`): Single-responsibility services for each domain (Auth, Forum, Grade, Profile, etc.)
- **Models** (`lib/models/`): Firestore-mapped POJO classes with `fromMap()`/`toMap()` serialization
- **Widgets** (`lib/widgets/`): Reusable components (CustomButton, CustomInput, AppToast, etc.)

### Backend: Firebase + Cloud Functions
- **Firebase**: Auth (email/password), Firestore (NoSQL collections), Storage (images/files), Cloud Functions
- **Cloud Functions** (`functions/`): Node.js v20 environment
  - `sendOtpEmail()`: OTP verification via Nodemailer on registration
  - `cal()`: Grade calculation function (referenced in grade_service)
- **Firestore Collections**: `user`, `post`, `grade`, `subject`, `career`, `email_otp`, `classroom`, `comment`

## Critical Patterns & Conventions

### 1. **Error Handling & User Feedback**
- Custom `AuthException` class for auth-related errors
- **AppToast pattern** (`widgets/app_toast.dart`): All user feedback via `AppToast.success/error/info(context, msg)`
- Example: `AppToast.error(context, "Invalid credentials.");`
- Never use `ScaffoldMessenger.of(context).showSnackBar()` directly

### 2. **Service Architecture**
- Services encapsulate Firebase + business logic (e.g., `auth_service.dart`, `forum_service.dart`)
- Services expose clean async methods returning typed results or throwing domain exceptions
- Example flow (login_page.dart):
  ```dart
  final result = await _authService.login(input, pass);
  final role = (result['role'] ?? '').toString().toLowerCase();
  ```

### 3. **Firestore Data Mapping**
- Collections use snake_case keys: `user_id`, `user_role`, `post_title`, `post_time`
- Models implement `toMap()` → Firestore and `fromMap()` → Model
- Example (UserModel): 
  ```dart
  toMap() => {'user_id': userId, 'user_role': role, ...}
  fromMap() => UserModel(userId: map['user_id'], ...)
  ```

### 4. **Authentication & Role-Based Routing**
- Role variants: `'admin'`, `'teacher'`, `'student'` (case-insensitive, normalized in service)
- Login checks existing users by `user_code` (ID field) or email
- `_goByRole(role)` pattern redirects to `/admin`, `/teacher`, or `/student` home
- Authentication state recovered on app startup via `_redirectIfLoggedIn()`

### 5. **OTP Verification Workflow (Registration)**
- `RegisterService.sendOtp(email)`: 
  1. Validates email uniqueness in Auth + Firestore
  2. Generates 6-digit OTP via `Random.secure()`
  3. Stores in `email_otp` collection with 10min expiry
  4. Calls Cloud Function `sendOtpEmail()` to email code
- OTP validation happens in UI (verify code input before user creation)

### 6. **Forum Data Structure**
- Post documents in Firestore use auto-incrementing `post_id` (padded `'001'`, `'002'`)
- Posts support images: upload to Firebase Storage → URL stored in `post_image` field
- Forum images located at `gs://bucket/forum/{postId}/image.jpg`
- Comments stored in subcollection: `post/{postId}/comments/{commentId}`

### 7. **UI State Management**
- Simple `setState()` for page-level state (loading flags, form inputs)
- Example: `setState(() => loading = true)` during async operations
- TextEditingController initialization/disposal in StatefulWidget lifecycle

### 8. **Navigation Patterns**
- GoRouter push: `context.go('/path')` for navigation
- GoRouter parameters: `GoRoute(path: '/detail/:id', ...)` with `state.pathParameters['id']`
- Shell routes for role-based bottom nav (student/teacher/admin shells)

## Common Tasks & Commands

### Building & Running
```bash
# Get dependencies
flutter pub get

# Run app (default: debug)
flutter run

# Run on specific device
flutter run -d <device_id>

# List devices
flutter devices
```

### Cloud Functions Development
```bash
# From functions/ directory
npm run serve          # Start local emulator
firebase deploy --only functions  # Deploy to production
firebase functions:log # View logs
```

### Firestore Emulator (local development)
- Configure in `main.dart` during Firebase initialization if needed
- Production uses live Firestore from `firebase_options.dart`

## Code Style & Naming

- **Dart**: Snake_case for variables/methods, PascalCase for classes
- **Firestore fields**: Always snake_case (e.g., `user_code`, `post_title`, `otp_code`)
- **Boolean fields**: Prefix with `is_` or `_is` (e.g., `is_verified`, `is_active`)
- **Comments in Dart**: Thai comments acceptable; use `// ✅`, `// 🔹`, `// 🟦` emojis for clarity
- **Null safety**: Always use `?` for nullable, `??` for defaults, `!` only after validation

## Integration Points

### Firebase Auth ↔ Firestore Sync
- On successful login: fetch `user_role` from Firestore `user` collection
- On registration: create entry in both Auth (email/password) and Firestore `user` doc

### Cloud Functions ↔ Flutter
- RegisterService calls: `https://us-central1-rmutl-fullproject.cloudfunctions.net/sendOtpEmail` via `http.post()`
- Always handle CORS (functions set headers) and JSON parsing errors
- OTP function expects: `{email: "...", code: "123456"}`

### Storage ↔ Firestore
- Forum images: upload bytes → get URL → store URL in `post_image` field
- Example: `ForumService.uploadPostImage(Uint8List, postId) → URL`
- Profile avatars: `user_img` field in Firestore stores image URL

## Known Constraints & Gotchas

1. **Firebase Duplicate App**: `main.dart` handles duplicate app initialization (multiple Hot Reloads)
2. **Email OTP Expiry**: 10-minute window; always check `otp_expire` timestamp before validation
3. **Role Normalization**: Always call `.toLowerCase()` on role before switch/comparison
4. **Firestore Limits**: Single document max 1MB; use subcollections for large datasets (comments)
5. **Platform-Specific**: Android requires Google Play Services; iOS needs CocoaPods dependencies
6. **User Code Lookup**: Not all users have `user_code` field (imported users may be missing it)

## Recommended Workflow for New Features

1. **Add Firestore collection/fields** → update `models/` with new POJO
2. **Create/extend service** in `lib/services/` with fetch/create/update/delete methods
3. **Build UI page** in appropriate `ui/{role}/` folder, using the service
4. **Integrate into router** in `app_router.dart` with correct role shell
5. **Use AppToast** for all feedback; test on device or emulator
6. **Deploy Cloud Functions** (if needed) before shipping app update

## Testing Considerations

- UI testing: Flutter Driver or unit tests for services
- Integration: Test with Firebase emulator locally before deploying
- No existing unit/widget test files found; add to `test/` directory as needed
