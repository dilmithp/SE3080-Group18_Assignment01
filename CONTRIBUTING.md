# Contributing

## Branches

Branch off `main` using your component prefix:

```
feature/auth-trust/<short-description>
feature/profiles/<short-description>
feature/matching/<short-description>
feature/scheduling/<short-description>
```

Example: `feature/matching/geo-distance-filter`.

## Workflow

1. Branch from `main`.
2. Work inside your owned `features/<feature>/` folder (see the ownership
   table in README.md). Don't edit another feature's folder without asking
   its owner first.
3. Open a PR back into `main` using the template — fill in the checklist.
4. **Every PR needs at least one teammate's review before merging**,
   regardless of size.
5. **Changes to `core/` need review from at least two other teammates** —
   it's shared by all four features, so a bad change there blocks
   everyone, not just you.

## Code style

- Follow the Clean Architecture layering already in place: `presentation`
  and `domain` depend on abstractions only; only `data/` imports Firebase.
  `domain/` must have zero `package:firebase_*` imports — this is enforced
  by convention and by the PR checklist, not by tooling, so please actually
  check.
- Run `flutter analyze` before opening a PR. It must be clean.
- When you implement a stubbed use case or repository method, replace the
  `throw UnimplementedError(...)` body — don't leave it half-done, and
  don't return hardcoded fake data instead of wiring the real call.
- Match the existing pattern in `features/auth_trust/` for new
  entities/repositories/use cases/DTOs — it's the reference implementation
  every other feature copied from.

## Setup

See the "Getting started" section in README.md.
