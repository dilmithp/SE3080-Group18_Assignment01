/**
 * Scheduled session reminders (features/scheduling, owner: Ranketh).
 *
 * Runs every 15 minutes. For each confirmed session starting within the next
 * hour, it:
 *   - sends an FCM push to each participant who has a saved `fcmToken` on
 *     users/{uid} (no client saves tokens yet, so this is a no-op until one does);
 *   - always queues an email by writing a doc to the `mail` collection, which
 *     the Firebase "Trigger Email" extension sends (no paid SMS API);
 *   - records `reminder1hSentAt` on the session so it is not sent twice.
 *
 * Loaded from index.js after initializeApp() has run.
 */

const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { logger } = require('firebase-functions');
const {
  REMINDER_LEAD_MS,
  sessionsDueForReminder,
  buildRecipients,
  buildReminderEmail,
} = require('./reminders_logic');

const db = getFirestore();

async function remind(session) {
  const profileNames = {};
  for (const uid of buildRecipients(session)) {
    const [userSnap, profileSnap] = await Promise.all([
      db.collection('users').doc(uid).get(),
      db.collection('profiles').doc(uid).get(),
    ]);
    const user = userSnap.data() || {};
    const name = profileSnap.data()?.displayName;
    profileNames[uid] = name;

    if (user.fcmToken) {
      try {
        await getMessaging().send({
          token: user.fcmToken,
          notification: {
            title: 'Visit starting soon',
            body: 'Your CareConnect visit starts in about an hour.',
          },
          data: { type: 'session_reminder', sessionId: session.id },
        });
      } catch (error) {
        logger.warn('FCM reminder failed', { uid, error: error.message });
      }
    }

    if (user.email) {
      const email = buildReminderEmail(session, name);
      await db.collection('mail').add({ to: user.email, message: email });
    }
  }

  await db.collection('sessions').doc(session.id).update({
    reminder1hSentAt: FieldValue.serverTimestamp(),
  });
}

exports.sendSessionReminders = onSchedule(
  { schedule: 'every 15 minutes', timeZone: 'Asia/Colombo' },
  async () => {
    const now = Date.now();
    const snap = await db
      .collection('sessions')
      .where('scheduledAtMillis', '>', now)
      .where('scheduledAtMillis', '<=', now + REMINDER_LEAD_MS)
      .get();

    const due = sessionsDueForReminder(
      snap.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
      now
    );
    for (const session of due) {
      try {
        await remind(session);
      } catch (error) {
        logger.error('Session reminder failed', { sessionId: session.id, error: error.message });
      }
    }
  }
);
