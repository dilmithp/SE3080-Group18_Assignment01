# Elderly Companionship & Micro-Volunteering Platform

SE3080 — Group 018. A mobile app connecting elderly individuals in a
locality with student/community volunteers for companionship and small
everyday help (grocery runs, walks, conversation, basic tech support).

Core loop: a user posts a need or availability → the system matches them
with a suitable, verified counterpart → a session is booked → after the
session, feedback feeds back into a trust score.

## Stack

- **Flutter** (Dart, null-safe)
- **Firebase**: Authentication, Cloud Firestore, Storage, Cloud Messaging, Cloud Functions
- **State management / DI**: Riverpod (`flutter_riverpod`) — manual providers, no code generation
- **Routing**: `go_router`
- **Value equality**: `freezed` + `json_serializable`, used for data-layer DTOs only
- **Functional error handling**: `dartz` (`Either<Failure, T>`)
- **Testing**: `flutter_test`, `mocktail`

## Getting started

This repo was scaffolded by hand (no `flutter create` was run against it),
so the platform runner folders (`android/`, `ios/`, etc.) don't exist yet.
Generate them first — this only adds the missing platform folders, it
won't touch `lib/` or `pubspec.yaml`, but run `git status` afterwards and
revert anything unexpected before committing:

```bash
flutter create . --project-name elderly_companion --org com.se3080.group18 --platforms=android,ios
git status   # sanity check — should show new android/ and ios/ folders only
```

```bash
flutter pub get

# Generates the data-layer freezed/json_serializable code (*.freezed.dart,
# *.g.dart). These are gitignored — run this after every clone and after
# editing any file with an @freezed class.
dart run build_runner build --delete-conflicting-outputs

# Wires this project to a real Firebase project and generates
# lib/core/config/firebase_options.dart (also gitignored — contains
# project keys, never commit it). Requires the FlutterFire CLI:
# dart pub global activate flutterfire_cli
flutterfire configure

flutter analyze
flutter run
```

You do **not** need `flutterfire configure` to be done to run the app —
`main.dart` swallows the Firebase init failure so the placeholder UI is
still navigable before Firebase is set up. You do need it before any
feature that actually talks to Firebase will work.

## Architecture

Feature-first Clean Architecture, three layers per feature:

```
lib/
├── main.dart / app.dart
├── core/                     # shared — see "core/ is shared" below
│   ├── config/                 env + collection-name constants, firebase_options.dart (gitignored)
│   ├── di/                     shared service providers (Firestore/Storage/Notification)
│   ├── error/                  sealed Failure hierarchy + data-layer exceptions
│   ├── routing/                go_router config, route names, auth redirect guard
│   ├── theme/                  accessible theme, colors, typography, AccessibilityController
│   ├── widgets/                AppButton, AppTextField, AppCard, LoadingView, ErrorView, EmptyView
│   ├── services/                thin Firebase wrappers (no business logic)
│   └── utils/                  validators, extensions
└── features/
    ├── auth_trust/    (Pathirana)  — reference implementation, copy this pattern
    ├── profiles/      (Perera)
    ├── matching/      (Wijekoon)
    └── scheduling/    (Ranketh)
```

Each feature folder:

```
features/<feature>/
├── data/
│   ├── models/          freezed DTOs, Firestore-shaped, toJson/fromJson
│   ├── datasources/     <Feature>RemoteDataSource — abstract + Firebase impl
│   └── repositories/    <X>RepositoryImpl — implements the domain interface
├── domain/
│   ├── entities/        pure Dart, zero Firebase imports — hard rule
│   ├── repositories/    abstract interfaces only
│   └── usecases/        one class per business rule, single call()
└── presentation/
    ├── providers/       Riverpod wiring: datasource → repository → usecases
    ├── screens/
    └── widgets/
```

### SOLID, concretely

- **S** — repositories only do data access; use cases hold one rule each; widgets only render.
- **O** — new behaviour is a new use case or a new interface implementation. See `features/matching/domain/strategies/matching_strategy.dart`: a second matching heuristic is a new `MatchingStrategy`, not a branch in the existing one.
- **L** — any repository implementation must be swappable for another behind the same interface with no caller changes (a fake used in tests included).
- **I** — no god-interfaces. `AuthRepository` / `VerificationRepository` / `TrustScoreRepository` and `SessionRepository` / `FeedbackRepository` are deliberately split so a screen only depends on what it actually calls.
- **D** — `presentation`/`domain` depend on abstractions; only `data/` imports Firebase. Wiring happens in each feature's `presentation/providers/` (plus the shared singletons in `core/di/injection.dart`).

### Current state

This is a **scaffold**, not a finished app. Every use case and repository
method throws `UnimplementedError('TODO(<owner>): ...')` — grep for
`TODO(` to find every stub. The two exceptions are:
- `core/` infra (theme, routing, shared services) — real and working.
- `features/matching/domain/strategies/matching_strategy.dart`'s
  `DefaultMatchingStrategy.score()` — real pure-Dart scoring logic, used
  to demonstrate the Open/Closed pattern above.

Every route is reachable and every screen renders — see
`core/routing/app_router.dart`. Sign-in/sign-up screens have a
"Continue without an account (dev preview)" button so the rest of the team
isn't blocked navigating the app while `auth_trust` is still being built —
remove it once sign-in is real.

## Data model

See [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) for the Firestore collection
layout and [`firestore.rules`](firestore.rules) for access control.

## Component ownership

| Member | Branch prefix | Owns |
|---|---|---|
| Pathirana P P D S S (IT23534254) | `feature/auth-trust` | `features/auth_trust/` — authentication, RBAC, verification workflow, trust score |
| Perera K K L A (IT23670334) | `feature/profiles` | `features/profiles/` — profile models & screens, accessibility framework, design system |
| Wijekoon W M V M (IT23600416) | `feature/matching` | `features/matching/` — matching algorithm, search/filters, geolocation |
| Ranketh K A D (IT23543300) | `feature/scheduling` | `features/scheduling/` — booking lifecycle, calendar, reminders, feedback |

**`core/` is shared — changes there need a PR reviewed by at least two
members** to avoid merge conflicts and accidental breakage of another
feature's dependency on it.

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full workflow and PR rules.
