/**
 * Account security Cloud Functions (features/auth_trust, owner: Pathirana).
 *
 *   - revokeAllSessions: callable. Revokes every refresh token for the
 *     caller so all devices must sign in again. The calling device signs out
 *     locally; its current ID token stays valid until it expires (about an
 *     hour), so this is not an instant kill switch for that one device.
 *   - auditVerificationReview: writes one `auditLogs` entry each time a
 *     verification request is approved or rejected. firestore.rules denies
 *     every client write to auditLogs, so only this trigger can create them.
 *
 * Loaded from index.js after initializeApp() has run.
 */

const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');

const db = getFirestore();

exports.revokeAllSessions = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in first.');
  }
  await getAuth().revokeRefreshTokens(request.auth.uid);
  return { revoked: true };
});

exports.auditVerificationReview = onDocumentUpdated(
  'verification_requests/{requestId}',
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (before.status === after.status) return;
    if (after.status !== 'approved' && after.status !== 'rejected') return;

    await db.collection('auditLogs').add({
      action: `verification_${after.status}`,
      requestId: event.params.requestId,
      targetUserId: after.userId,
      actorId: after.reviewedBy ?? null,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
);
