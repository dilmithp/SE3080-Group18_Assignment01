# Data Model

Cloud Firestore, top-level collections. Every field name below matches the
corresponding domain entity — the data-layer DTOs (`data/models/`) are the
only place that knows about this document shape; see each feature's
`data/datasources/` for the Firestore reads/writes.

Access rules for every collection live in [`firestore.rules`](../firestore.rules).

## `users/{userId}`
Owner: **auth_trust** (Pathirana) · entity: `AppUser`

| Field | Type | Notes |
|---|---|---|
| `email` | string | |
| `phone` | string | |
| `role` | string | `elderly` \| `volunteer` \| `admin` |
| `isVerified` | bool | mirrors latest approved `verification_requests` doc |
| `createdAt` | timestamp | |

Doc ID = Firebase Auth UID.

## `verification_requests/{requestId}`
Owner: **auth_trust** (Pathirana) · entity: `VerificationRequest`

| Field | Type | Notes |
|---|---|---|
| `userId` | string | ref to `users/{userId}` |
| `documentUrl` | string | Storage download URL, see `verification_documents/` path |
| `status` | string | `pending` \| `approved` \| `rejected` |
| `reviewedBy` | string? | admin `userId`, null until reviewed |
| `reviewedAt` | timestamp? | null until reviewed |

## `trust_scores/{userId}`
Owner: **auth_trust** (Pathirana) · entity: `TrustScore`

| Field | Type | Notes |
|---|---|---|
| `score` | number | written by a Cloud Function, never the client |
| `completedSessions` | int | |
| `averageRating` | number | derived from `session_feedback` |
| `lastUpdated` | timestamp | |

Doc ID = `userId`. Recomputed by a Cloud Function trigger on
`session_feedback` writes (not implemented in this scaffold — see the
`TrustScoreRepository` TODOs).

## `profiles/{userId}`
Owner: **profiles** (Perera) · entity: `UserProfile`

| Field | Type | Notes |
|---|---|---|
| `displayName` | string | |
| `photoUrl` | string? | Storage download URL, see `profile_photos/` path |
| `bio` | string | |
| `locality` | string | free-text locality/neighbourhood |
| `geoPoint` | geopoint | Firestore native `GeoPoint` — mapped to the domain-safe `GeoCoordinates` value type at the data boundary |
| `skillsOffered` | array\<string\> | |
| `helpNeeded` | array\<string\> | |
| `availabilityWindows` | array\<map\> | `{ dayOfWeek, startTime, endTime }` |
| `accessibilityPrefs` | map | `{ largeText, highContrast, simplifiedInterface, communicationNotes }` |

Doc ID = `userId` (same as `users/{userId}`).

## `sessions/{sessionId}`
Owner: **scheduling** (Ranketh) · entity: `Session`

| Field | Type | Notes |
|---|---|---|
| `requesterId` | string | ref to `users/{userId}` |
| `volunteerId` | string | ref to `users/{userId}` |
| `scheduledAt` | timestamp | |
| `durationMinutes` | int | |
| `status` | string | `requested` \| `confirmed` \| `completed` \| `cancelled` |
| `location` | string | |
| `notes` | string? | |

## `session_feedback/{feedbackId}`
Owner: **scheduling** (Ranketh) · entity: `SessionFeedback`

| Field | Type | Notes |
|---|---|---|
| `sessionId` | string | ref to `sessions/{sessionId}` |
| `raterId` | string | ref to `users/{userId}` |
| `rating` | int | 1–5 |
| `comment` | string? | |
| `createdAt` | timestamp | |

## Not a collection: matching

**matching** (Wijekoon) doesn't own a collection — `MatchCandidate` results
are computed on read (query `profiles` by locality/skills, optionally via a
Cloud Function for geo-distance and trust-score weighting) rather than
stored. If caching computed matches turns out to be needed for performance,
add a `match_cache/{userId}` collection and update this doc + the rules
file together.
