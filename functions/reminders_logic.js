/**
 * Pure reminder rules (features/scheduling, owner: Ranketh). No Firebase
 * imports, so these run under `node --test` without emulators.
 *
 * A reminder goes out once, one hour before a confirmed session starts. The
 * reminder is recorded on the session as `reminder1hSentAt`, so a later run
 * of the scheduler does not send it again.
 */

const REMINDER_LEAD_MS = 60 * 60 * 1000;

/**
 * Confirmed sessions starting within the next hour that have not been
 * reminded yet.
 */
function sessionsDueForReminder(sessions, nowMs) {
  return sessions.filter(
    (s) =>
      s.status === 'confirmed' &&
      typeof s.scheduledAtMillis === 'number' &&
      s.scheduledAtMillis > nowMs &&
      s.scheduledAtMillis <= nowMs + REMINDER_LEAD_MS &&
      !s.reminder1hSentAt
  );
}

/** Both participants of a session get the reminder. */
function buildRecipients(session) {
  return [session.requesterId, session.volunteerId].filter(Boolean);
}

/**
 * Subject and plain-text body for the reminder email. Times are shown in
 * Sri Lanka time because that is where the platform runs.
 */
function buildReminderEmail(session, recipientName) {
  const startsAt = new Date(session.scheduledAtMillis).toLocaleString('en-GB', {
    timeZone: 'Asia/Colombo',
    dateStyle: 'medium',
    timeStyle: 'short',
  });
  const greeting = recipientName ? `Hello ${recipientName},` : 'Hello,';
  return {
    subject: 'Reminder: your CareConnect visit starts in about an hour',
    text:
      `${greeting}\n\n` +
      `Your visit starts at ${startsAt} (Sri Lanka time) at: ${session.location}.\n\n` +
      'Open CareConnect for the details.',
  };
}

module.exports = { REMINDER_LEAD_MS, sessionsDueForReminder, buildRecipients, buildReminderEmail };
