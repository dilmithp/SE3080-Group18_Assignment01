# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Elderly Companionship & Micro-Volunteering Platform (SE3080 Group 018) — a
Flutter/Firebase app matching elderly users with volunteers for
companionship and small everyday help. Core loop: post a need/availability
→ match → book a session → post-session feedback feeds a trust score.

**This is a scaffold, not a finished app.** Every use case and repository
method throws `UnimplementedError('TODO(<owner>): ...')` — grep for `TODO(`
to find stubs. The only real business logic is `core/` infra (theme,
routing, shared services, all working) and
`features/matching/domain/strategies/matching_strategy.dart`'s
`DefaultMatchingStrategy.score()`, a pure-Dart scoring function kept as the
worked example of the Open/Closed pattern below. When implementing a stub,
replace the `throw UnimplementedError(...)` body fully — no hardcoded fake
data, no half-finished implementations.

Sign-in/sign-up screens have a "Continue without an account (dev preview)"
button so navigation isn't blocked while `auth_trust` is being built —
remove it once real sign-in lands.

## Commands

```bash
# First-time setup only — adds android/ios runner folders (this repo was
# hand-scaffolded, flutter create was never run against it). Won't touch
# lib/ or pubspec.yaml, but check `git status` after and revert anything
# unexpected.
flutter create . --project-name elderly_companion --org com.se3080.group18 --platforms=android,ios

flutter pub get

# Regenerate *.freezed.dart / *.g.dart (gitignored). Run after every clone
# and after editing any file with an @freezed class.
dart run build_runner build --delete-conflicting-outputs

# Wires the project to a real Firebase project, generates the (gitignored)
# lib/core/config/firebase_options.dart. Requires:
#   dart pub global activate flutterfire_cli
# Not needed to run the app — main.dart swallows Firebase init failure so
# the placeholder UI is still navigable — but needed for any feature that
# actually talks to Firebase.
flutterfire configure

flutter analyze          # must be clean before opening a PR
flutter run
flutter test                                  # full suite
flutter test test/features/auth_trust/auth_repository_test.dart   # single file
```

## Architecture

Feature-first Clean Architecture, three layers per feature, under
`lib/features/{auth_trust,profiles,matching,scheduling}/`:

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

`lib/core/` is shared across all features: `config/` (env + collection-name
constants, gitignored `firebase_options.dart`), `di/injection.dart` (shared
Firestore/Storage/Notification service singletons — feature-specific
wiring lives in each feature's `presentation/providers/`, not here), `error/`
(sealed `Failure` hierarchy + data-layer exceptions), `routing/` (go_router
config + auth redirect guard), `theme/` (accessible theme incl.
`AccessibilityController`), `widgets/` (AppButton, AppTextField, AppCard,
LoadingView, ErrorView, EmptyView), `services/` (thin Firebase wrappers,
no business logic), `utils/` (validators, extensions).

`features/auth_trust/` is the reference implementation — match its pattern
when adding entities/repositories/use cases/DTOs in another feature.

### Layering rule (enforced by convention/PR review, not tooling)

`presentation/` and `domain/` depend on abstractions only; **only `data/`
imports Firebase** (`package:firebase_*`, `package:cloud_firestore`, etc.).
`domain/` must have zero Firebase imports. Error handling is functional:
repositories return `Either<Failure, T>` (`dartz`), never throw across
layer boundaries.

### Open/Closed in practice

A new matching heuristic is a new `MatchingStrategy` implementation (see
`features/matching/domain/strategies/matching_strategy.dart`), never a
branch inside `DefaultMatchingStrategy`. Apply the same pattern
elsewhere: new behavior = new interface implementation, not a conditional
in existing code.

### Data model

Firestore collections and field shapes are documented in
[`docs/DATA_MODEL.md`](docs/DATA_MODEL.md); access rules live in
[`firestore.rules`](firestore.rules). Both must stay in sync with any
`data/models/` change. Each collection's owning feature is noted there —
`matching` computes results on read and owns no collection of its own.

### Ownership (branch prefixes — see README.md for names)

| Feature | Branch prefix |
|---|---|
| `features/auth_trust/` | `feature/auth-trust` |
| `features/profiles/` | `feature/profiles` |
| `features/matching/` | `feature/matching` |
| `features/scheduling/` | `feature/scheduling` |

Don't edit another feature's folder without asking its owner first.
**Changes to `core/` need review from at least two other teammates** — it's
shared by every feature, so bugs there block everyone.

## Testing pattern

Mock the abstract repository *interface* (never a Firebase implementation)
with `mocktail`, stub the method under test, assert on the domain-level
`Either` result. See `test/features/auth_trust/auth_repository_test.dart`
for the canonical shape — copy it for new use-case/repository tests.
