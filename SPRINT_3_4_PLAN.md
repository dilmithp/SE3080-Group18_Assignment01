# CareConnect — Sprint 3 & 4 Plan (SE3080 Group 018)

**Window:** Fri 11 Sep 2026, 00:00 → Sun 4 Oct 2026, 08:00 (23 days)
**Split:** two ~2-week sprints, with all feature development finished by **Wed 30 Sep**, leaving
**Thu 1 Oct – Sun 4 Oct** as a dedicated hardening/submission buffer (no new features in that window).

| Sprint | Dates | Length | Focus |
|---|---|---|---|
| Sprint 3 | Fri 11 Sep – Thu 24 Sep 2026 | 14 days | Deepen each component; close the core match→book→session→feedback→trust loop |
| Sprint 4 | Fri 25 Sep – Sun 4 Oct 2026 | 10 days (dev ends Wed 30 Sep) | Stretch features, full localization/accessibility, hardening, submission |

Builds on the existing plan: Sprint 0 (28 Jul–3 Aug, setup), Sprint 1 (4–14 Aug, register/profile/discover),
Sprint 2 (15–24 Aug, match/book/feedback) — see `project-component-ownership` notes.

---

## Team & component ownership (unchanged from Assignment 01)

| Member | Role | Core component | Branch prefixes |
|---|---|---|---|
| Pathirana P P D S S | Dev | Identity, Access & Trust Management (`features/auth_trust/`) | `feature/auth`, `feature/trust-score` |
| Perera K K L A | Dev | User Profiles & Accessibility Framework (`features/profiles/` + shared design system) | `feature/profiles`, `feature/design-system` |
| Wijekoon W M V M | Product Owner | Matching & Discovery Engine (`features/matching/`) | `feature/matching`, `docs/backlog` |
| Ranketh K A D | Scrum Master | Scheduling, Sessions & Community Feedback (`features/scheduling/`) | `feature/scheduling`, `docs/scrum-artifacts` |

Features added beyond the original four components are distributed below, matched to whoever
it most naturally extends — Wijekoon picks up messaging (chat with a match) and referrals
(growth, PO-driven); Ranketh picks up the community feed (it's literally in his component name).

---

## Sprint 3 (11–24 Sep) — Core depth + integration

**Sprint goal:** every component has real, working business logic behind it (no more
`UnimplementedError` stubs in the four core features), and a session can be matched, booked,
and completed end-to-end by one real user flow.

| Member | Tasks |
|---|---|
| **Pathirana** (auth_trust) | Sign-in/sign-up + role selection flow; trust score entity + computation use case; verification-request submission (ID document upload to Storage); admin verification review queue (approve/reject) |
| **Perera** (profiles) | Profile CRUD (view/edit) + completeness scoring widget; emergency contact card + safety-preference chips; location picker + Google Maps (mobile + web key config); shared design system (`AppButton`/`AppTextField`/`AppCard`, accessible theme, text-scale infra) |
| **Wijekoon** (matching, PO) | `MatchCandidate` entity + `MatchingStrategy` interface (Open/Closed design); `DefaultMatchingStrategy` scoring (distance/skills/trust/language/availability); matching screen (search, strategy picker, match reasons); backlog grooming + acceptance criteria for Sprint 4 |
| **Ranketh** (scheduling, SM) | `Session` entity + booking flow (request/confirm/cancel) with `SessionStatus` state machine; scheduling repository (Firestore-backed); check-in/check-out with time-window gating; sprint ceremonies + Trello board upkeep |

**Sprint 3 exit criteria:** one user can sign up → complete their profile → get matched →
book a session → check in/out, with all four components' core logic real (not stubbed).

---

## Sprint 4 (25 Sep – 4 Oct) — Stretch features, polish, hardening

**Dev cut-off: Wednesday 30 Sep.** Everything below must be code-complete by then.

| Member | Tasks (by 30 Sep) |
|---|---|
| **Pathirana** | FCM push registration + tap-to-route; trust-score explanation screen wired from profile; sign-out-all-devices Cloud Function; admin audit log for verification reviews; security-rules hardening pass |
| **Perera** | Full localization — English/Sinhala/Tamil (ARB sources, `gen-l10n`, every screen rewired); Accessibility Settings screen (high contrast, simplified mode, reduced motion, data saver, voice-guided prompts via TTS) + language picker; offline-connectivity banner; profile-photo upload to Storage |
| **Wijekoon** | Remaining matching strategies (Nearest / Most trusted / Best skill match / Shares my language / Free when I am); messaging feature (conversations list + chat, Firestore-backed); referrals feature (generate/redeem/track) + its Firestore rules/indexes |
| **Ranketh** | Session feedback → feeds trust score (closes the core loop); calendar (ICS) export for booked sessions; community feed screen; session-reminder scheduled Cloud Function (built, pending Blaze-plan deploy); full regression pass before hand-off |

### 1–4 Oct — all hands, no new features

- Final `flutter analyze` (0 issues) + full `flutter test` run, green.
- Bug triage from the regression pass — fix, don't add.
- Final release APK build + install/demo smoke test on a real device.
- `docs/DATA_MODEL.md` and `firestore.rules`/`storage.rules` reconciled with whatever shipped.
- Viva/demo rehearsal — one full run-through of the planned demo script.
- Report + submission packaging (due Sun 4 Oct, 08:00).

---

## Load balance check

Each member owns 4 Sprint-3 tasks + 4–5 Sprint-4 tasks of comparable size (one entity/use-case
layer, one Firestore-backed flow, one UI screen, one cross-cutting concern) — no one is carrying
a second person's component, and the two leadership roles (PO, SM) keep their process duties
alongside a full dev task list rather than instead of one.
