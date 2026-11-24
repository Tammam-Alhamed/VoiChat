# VoiChat project instructions

## Working agreement

- Treat this as an established application. Preserve its directory layout, naming, user-facing behavior, and existing architectural choices unless the task explicitly asks to change them.
- Before implementing anything, search the whole `lib/` tree for the relevant screen, widget, state object, model, API call, navigation path, asset, and localization keys. Reuse or extend what is already there; do not add a second implementation of an existing capability.
- Read the target files and their callers before editing. Keep changes scoped to the requested feature and its necessary integration points. Avoid unrelated cleanup, broad refactors, new layers, new packages, and moving files.
- Existing user edits are part of the working tree. Inspect `git status` first and preserve all changes you did not make for the current task.
- Do not invent backend routes, request/response fields, or product behavior. Follow the contracts visible in the existing feature; call out missing contract details when they prevent a safe implementation.
- When the user supplies a reference design, match its colors, typography, spacing, and interaction before considering the UI complete. Keep the implementation within the feature's existing code structure and shared components.

## Current project map

- Flutter application source is under `lib/`; app startup is in `lib/main.dart`.
- `lib/app/di/` owns GetIt setup and app-wide GetX controller registration. Feature registrations live in each feature's `*_injection.dart` where present.
- `lib/core/` contains shared networking, session handling, storage, themes, localization, helpers, and reusable widgets. Add shared code there only when it is genuinely shared by more than one feature.
- `lib/features/` is feature-oriented. Some newer features (`auth`, `session`, `discover`, `live`, `recent_calls`, and `followings`) use data/domain/presentation layers. Several established features use Provider state classes or direct `ServiceHelper` calls. Follow the local feature's existing pattern; do not migrate state management or architecture as part of an unrelated task.
- `lib/testlivekit/` contains substantial LiveKit and live-room screens that already call shared services and providers. Inspect this directory before adding live-stream or room behavior; do not assume the word `test` means the code is disposable or unused.
- Call-history behavior exists in both `features/calls/data/call_repository.dart` and `features/recent_calls/data/datasources/recent_calls_remote_data_source.dart` (including the `/v1/calls/history` API). Check both paths and their screens before changing or adding call-history behavior; do not create another history implementation.
- Native project files live under `android/`, `ios/`, `linux/`, `macos/`, `web/`, and `windows/`. Touch platform configuration only when the requested behavior requires it.
- `assets/` holds app images, icons, audio, gifts, and fonts. Register new asset directories or fonts in `pubspec.yaml` and use existing assets when they already meet the need.
- `pubspec.lock` is committed. Avoid dependency changes unless needed for the requested task.
- `lib/core/structure.txt` is a legacy outline and does not match the current repository. Use the checked-in tree and actual imports/registration as the source of truth; do not reorganize the app to match that outline.

## Existing conventions and integration points

- Startup initializes GetIt (`di.init()`), GetStorage, Firebase where supported, GetX navigation, Provider state, ScreenUtil, themes, and localization in `lib/main.dart`. Preserve this lifecycle when adding startup behavior.
- The app currently uses GetX for navigation and some controllers, Provider/ChangeNotifier for other state, and GetIt for dependency injection. Do not introduce another state-management or service-locator system or convert existing features without an explicit request.
- Shared REST calls go through `core/network/service_helper.dart`; it handles headers, responses, and errors. New endpoint calls should follow the target feature's established remote-data-source/repository path where one exists. Avoid adding a parallel HTTP client or duplicate response handling.
- `core/network/socket_service.dart` owns the shared Socket.IO connection and event streams. Search for existing events/listeners before adding socket behavior, and preserve listener cleanup and session lifecycle.
- `core/session/session_manager.dart` coordinates logout/session expiry, storage cleanup, socket shutdown, and reset hooks. Keep account-scoped cleanup and device preferences consistent with `StoreHelper`.
- Server URLs and profile links are centralized in `core/constants.dart`. Do not scatter a duplicate base URL or SFU URL through new code.
- User-visible strings use GetX localization maps in `core/localization/` (`ar`, `en`, `es`, `fr`, `it`, `ru`). When adding a localized string, add the same key to every locale and use the existing translation lookup pattern.
- Shared theme colors and extensions live in `core/themes/`; prefer them over hard-coded colors when matching existing app surfaces.
- Keep back-arrow and adjacent title content aligned with `SettingsAppBar` across settings and support pages: a 44-pixel leading slot and 4-pixel title spacing. When a header includes an avatar, begin the avatar at the same title-content position and keep its following title spacing consistent with the reference design.

## Change quality

- Preserve existing public APIs and behavior unless the task requires a change. Check callers before changing method signatures, persisted keys, socket event names, or navigation behavior.
- Prefer the smallest complete change. Keep widgets, state, and API work at the layer already used by the feature; extract shared code only when there is a real reuse case.
- Match the surrounding Dart style and existing null/error/loading-state handling. Dispose controllers, subscriptions, animation controllers, and other owned resources according to the nearby pattern.
- Keep credentials, tokens, personal data, and raw authenticated request/response bodies out of new logs. Do not expose or alter local service configuration unless asked.
- Do not edit generated or build output (`build/`, `.dart_tool/`, generated plugin registrants) as application source.
- Do not add or run tests unless the user asks. If checks are requested, choose the narrowest useful Flutter/Dart checks and report exactly what ran and its result.
- Before finishing, review the diff and working-tree status to ensure the change is limited to the requested work and did not overwrite pre-existing edits.
