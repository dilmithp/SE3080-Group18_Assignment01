/**
 * Cloud Functions for `trust_scores/{userId}`.
 *
 * `trust_scores` is documented in docs/DATA_MODEL.md as "written by a Cloud
 * Function, never the client" and firestore.rules enforces `allow write: if
 * false;` on the collection — only the Admin SDK (used here, which bypasses
 * security rules) can write it. These triggers are that missing piece:
 *
 *   - recomputeTrustScoreOnFeedback: fires when a `session_feedback` doc is
 *     created, resolves who the feedback is about via the referenced
 *     session, and recomputes that person's trust score.
 *   - recomputeTrustScoreOnSessionCompletion: fires when a `sessions` doc's
 *     `status` transitions to 'completed', and recomputes the trust score
 *     for both participants (a completed session bumps `completedSessions`
 *     independent of whether feedback has been left yet).
 *
 * Both triggers funnel into the shared `recomputeTrustScoreFor(userId)`
 * helper, which is the single source of truth for how a trust score is
 * derived from `sessions` + `session_feedback`.
 */

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');

initializeApp();
const db = getFirestore();

/** Firestore's `in` operator accepts at most 30 values per query. */
const FIRESTORE_IN_CHUNK_SIZE = 30;

/**
 * Splits `array` into chunks of at most `size` elements each.
 */
function chunk(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

/**
 * Recomputes and persists `trust_scores/{userId}` from the current state of
 * `sessions` and `session_feedback`.
 *
 * completedSessions = count of distinct sessions where `userId` participated
 * (as requester or volunteer) and `status === 'completed'`.
 *
 * averageRating = mean `rating` (1-5) across `session_feedback` docs that
 * reference one of those completed sessions and were NOT written by
 * `userId` themselves (i.e. feedback ABOUT this user, not BY them) —
 * rounded to 1 decimal place, or 0 if there is no such feedback yet.
 *
 * score = a simple composite placeholder heuristic the team can tune later:
 *   score = min(100, completedSessions * 5 + averageRating * 10)
 * i.e. 5 points per completed session (capped implicitly by the min(100,_)
 * ceiling) plus up to 50 points for a perfect 5.0 average rating.
 */
async function recomputeTrustScoreFor(userId) {
  // Firestore can't OR across different fields in one query, so run two
  // queries and merge+dedupe the resulting session IDs.
  const [asRequesterSnap, asVolunteerSnap] = await Promise.all([
    db.collection('sessions')
      .where('requesterId', '==', userId)
      .where('status', '==', 'completed')
      .get(),
    db.collection('sessions')
      .where('volunteerId', '==', userId)
      .where('status', '==', 'completed')
      .get(),
  ]);

  const completedSessionIds = new Set([
    ...asRequesterSnap.docs.map((doc) => doc.id),
    ...asVolunteerSnap.docs.map((doc) => doc.id),
  ]);

  const completedSessions = completedSessionIds.size;

  // Gather feedback ABOUT userId (raterId !== userId) for those sessions.
  // Since every gathered session has userId as one of exactly two
  // participants, and the feedback's raterId is not userId, the feedback
  // is necessarily about userId — no extra cross-check query needed.
  const ratings = [];
  if (completedSessionIds.size > 0) {
    const sessionIdChunks = chunk([...completedSessionIds], FIRESTORE_IN_CHUNK_SIZE);
    const feedbackSnaps = await Promise.all(
      sessionIdChunks.map((ids) =>
        db.collection('session_feedback').where('sessionId', 'in', ids).get()
      )
    );
    for (const snap of feedbackSnaps) {
      for (const doc of snap.docs) {
        const feedback = doc.data();
        if (feedback.raterId !== userId && typeof feedback.rating === 'number') {
          ratings.push(feedback.rating);
        }
      }
    }
  }

  const averageRating =
    ratings.length > 0
      ? Math.round((ratings.reduce((sum, r) => sum + r, 0) / ratings.length) * 10) / 10
      : 0;

  const score = Math.min(100, completedSessions * 5 + averageRating * 10);

  await db.collection('trust_scores').doc(userId).set(
    {
      score,
      completedSessions,
      averageRating,
      lastUpdated: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

/**
 * Trigger: a `session_feedback/{feedbackId}` doc was created. Resolve who
 * the feedback is about (the "ratee") via the referenced session, then
 * recompute that person's trust score.
 */
exports.recomputeTrustScoreOnFeedback = onDocumentCreated(
  'session_feedback/{feedbackId}',
  async (event) => {
    try {
      const feedback = event.data?.data();
      if (!feedback) {
        logger.warn('recomputeTrustScoreOnFeedback: no feedback data on event, exiting.');
        return;
      }

      const { sessionId, raterId } = feedback;
      if (!sessionId || !raterId) {
        logger.warn(
          `recomputeTrustScoreOnFeedback: feedback ${event.params.feedbackId} missing sessionId/raterId, exiting.`
        );
        return;
      }

      const sessionSnap = await db.collection('sessions').doc(sessionId).get();
      if (!sessionSnap.exists) {
        logger.warn(
          `recomputeTrustScoreOnFeedback: session ${sessionId} referenced by feedback ${event.params.feedbackId} does not exist, exiting.`
        );
        return;
      }

      const session = sessionSnap.data();
      let rateeId;
      if (session.requesterId === raterId) {
        rateeId = session.volunteerId;
      } else if (session.volunteerId === raterId) {
        rateeId = session.requesterId;
      } else {
        logger.warn(
          `recomputeTrustScoreOnFeedback: raterId ${raterId} on feedback ${event.params.feedbackId} matches neither participant of session ${sessionId}, exiting.`
        );
        return;
      }

      await recomputeTrustScoreFor(rateeId);
    } catch (error) {
      console.error('recomputeTrustScoreOnFeedback failed:', error);
      throw error;
    }
  }
);

/**
 * Trigger: a `sessions/{sessionId}` doc was updated. If `status` just
 * transitioned TO 'completed' FROM something else, recompute the trust
 * score for both participants.
 */
exports.recomputeTrustScoreOnSessionCompletion = onDocumentUpdated(
  'sessions/{sessionId}',
  async (event) => {
    try {
      const before = event.data?.before?.data();
      const after = event.data?.after?.data();
      if (!before || !after) {
        logger.warn('recomputeTrustScoreOnSessionCompletion: missing before/after data, exiting.');
        return;
      }

      const becameCompleted = before.status !== 'completed' && after.status === 'completed';
      if (!becameCompleted) {
        return;
      }

      const { requesterId, volunteerId } = after;
      if (!requesterId || !volunteerId) {
        logger.warn(
          `recomputeTrustScoreOnSessionCompletion: session ${event.params.sessionId} missing requesterId/volunteerId, exiting.`
        );
        return;
      }

      await Promise.all([
        recomputeTrustScoreFor(requesterId),
        recomputeTrustScoreFor(volunteerId),
      ]);
    } catch (error) {
      console.error('recomputeTrustScoreOnSessionCompletion failed:', error);
      throw error;
    }
  }
);
