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

Doc ID = `userId`. Recomputed by a Cloud Function trigger — see
[`functions/index.js`](../functions/index.js) (`recomputeTrustScoreOnFeedback`
on `session_feedback` creates, `recomputeTrustScoreOnSessionCompletion` on a
`sessions` status transition to `completed`). Not yet deployed — see
`functions/README.md` for deploy steps and the Blaze-plan requirement; until
deployed, `getTrustScore`/`watchTrustScore` will keep returning "not found"
for every user, which the UI already treats as a normal "new member" state
(see `TrustBadgeChip`).

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
| `emergencyContactName` | string? | optional safety contact name |
| `emergencyContactPhone` | string? | optional safety contact phone, dialed via `EmergencyContactCard`'s `tel:` link |

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

## `conversations/{conversationId}`
Owner: **messaging** · entity: `Conversation`

| Field | Type | Notes |
|---|---|---|
| `participantIds` | array\<string\> | exactly 2 UIDs |
| `lastMessageText` | string | empty until the first message is sent |
| `lastMessageAt` | timestamp | |
| `createdAt` | timestamp | |

Doc ID = the two participant UIDs sorted ascending and joined with `_`
(deterministic — "get or create" is a plain doc read/set by ID, no query
needed).

## `conversations/{conversationId}/messages/{messageId}`
Owner: **messaging** · entity: `ChatMessage`

| Field | Type | Notes |
|---|---|---|
| `senderId` | string | ref to `users/{userId}` |
| `text` | string | |
| `createdAt` | timestamp | |

Doc ID = auto-generated.

## `notifications/{notificationId}`
Owner: **notifications** · entity: `AppNotification`

| Field | Type | Notes |
|---|---|---|
| `userId` | string | ref to `users/{userId}` — the recipient |
| `type` | string | `session_confirmed` \| `session_cancelled` \| `session_completed` \| `feedback_received` \| `verification_approved` \| `verification_rejected` \| `other` |
| `title` | string | |
| `body` | string | |
| `relatedId` | string? | e.g. a `sessionId`; null when nothing to deep-link to |
| `isRead` | bool | |
| `createdAt` | timestamp | |

Doc ID = auto-generated. Written by whichever feature triggers the event
(scheduling on session status changes and feedback submission, auth_trust
on verification review) — the writer is usually a different user than
`userId`, the recipient.

## `community_posts/{postId}`
Owner: **community** (new, unassigned in the original team split) · entity: `CommunityPost`

| Field | Type | Notes |
|---|---|---|
| `authorId` | string | ref to `users/{userId}` |
| `authorName` | string | denormalized from the author's profile at write time |
| `authorPhotoUrl` | string? | denormalized from the author's profile at write time |
| `text` | string | |
| `createdAt` | timestamp | |

Doc ID = auto-generated. Posts are immutable once created — no `update`.

## Not a collection: matching

**matching** (Wijekoon) doesn't own a collection — `MatchCandidate` results
are computed on read (query `profiles` by locality/skills, optionally via a
Cloud Function for geo-distance and trust-score weighting) rather than
stored. If caching computed matches turns out to be needed for performance,
add a `match_cache/{userId}` collection and update this doc + the rules
file together.
