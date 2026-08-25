# Cloud Functions — trust score recomputation

Implements `trust_scores/{userId}` as documented in
[`docs/DATA_MODEL.md`](../docs/DATA_MODEL.md): a doc "written by a Cloud
Function, never the client." `firestore.rules` enforces `allow write: if
false;` on this collection client-side, so these Admin-SDK-backed triggers
(which bypass security rules) are the only writer.

Two Firestore triggers (2nd gen, `firebase-functions/v2/firestore`), both in
[`index.js`](index.js):

- `recomputeTrustScoreOnFeedback` — fires on `session_feedback` create.
- `recomputeTrustScoreOnSessionCompletion` — fires on `sessions` update,
  only acting when `status` transitions to `completed`.

Both call a shared `recomputeTrustScoreFor(userId)` helper that recounts
completed sessions and averages ratings from `session_feedback`, then
writes `score`, `completedSessions`, `averageRating`, and `lastUpdated` to
`trust_scores/{userId}`.

## Deployment

**Prerequisite — Blaze plan required.** Cloud Functions are not available
on Firebase's free Spark plan; the project must be upgraded to the
pay-as-you-go **Blaze** plan before these functions can deploy or run.
Blaze includes a free-tier allowance that comfortably covers light usage
(this project's expected volume), but it is billing-enabled — usage beyond
the free tier incurs real cost. This is a deliberate opt-in the team should
make knowingly (e.g. in the Firebase console under
**Project Settings → Usage and billing**) before anyone runs `deploy`.

**One-time tooling setup** (skip any step already done):

```bash
npm install -g firebase-tools
firebase login
```

**Install function dependencies:**

```bash
cd functions
npm install
```

**Deploy** (from the repo root, so `firebase.json` is picked up):

```bash
firebase deploy --only functions
```

## Known gaps

- **No backfill.** These triggers only act on *new* events (new
  `session_feedback` docs, or a `sessions` doc's `status` transitioning to
  `completed` going forward). Any session already marked `completed`, or
  feedback already written, before this function is deployed will **not**
  retroactively produce a `trust_scores` doc — that participant's trust
  score stays unset until a *new* qualifying event happens for them (new
  feedback, or another session status update). A one-off backfill script
  (iterate `sessions`/`session_feedback` and call the same recompute logic)
  is straightforward to add later but is out of scope here.
