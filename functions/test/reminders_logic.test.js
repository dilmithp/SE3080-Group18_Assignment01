const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  sessionsDueForReminder,
  buildRecipients,
  buildReminderEmail,
  REMINDER_LEAD_MS,
} = require('../reminders_logic');

const NOW = Date.UTC(2026, 9, 3, 6, 0, 0);

function session(overrides = {}) {
  return {
    id: 's1',
    status: 'confirmed',
    scheduledAtMillis: NOW + 30 * 60 * 1000,
    requesterId: 'elderly-1',
    volunteerId: 'volunteer-1',
    location: 'Colombo 07 library',
    ...overrides,
  };
}

test('a confirmed session starting within the hour is due', () => {
  const due = sessionsDueForReminder([session()], NOW);
  assert.equal(due.length, 1);
});

test('a session that already has a reminder is not due again', () => {
  const sent = session({ reminder1hSentAt: { seconds: 1 } });
  assert.deepEqual(sessionsDueForReminder([sent], NOW), []);
});

test('a session starting after the one-hour window is not due yet', () => {
  const later = session({ scheduledAtMillis: NOW + REMINDER_LEAD_MS + 1 });
  assert.deepEqual(sessionsDueForReminder([later], NOW), []);
});

test('a session that has already started is not due', () => {
  const past = session({ scheduledAtMillis: NOW - 1 });
  assert.deepEqual(sessionsDueForReminder([past], NOW), []);
});

test('requested and cancelled sessions are not reminded', () => {
  const requested = session({ status: 'requested' });
  const cancelled = session({ status: 'cancelled' });
  assert.deepEqual(sessionsDueForReminder([requested, cancelled], NOW), []);
});

test('both participants receive the reminder', () => {
  assert.deepEqual(buildRecipients(session()), ['elderly-1', 'volunteer-1']);
});

test('a missing participant id is skipped', () => {
  assert.deepEqual(buildRecipients(session({ volunteerId: '' })), ['elderly-1']);
});

test('the email names the recipient, the location and Sri Lanka time', () => {
  const email = buildReminderEmail(session(), 'Mary');

  assert.match(email.subject, /about an hour/);
  assert.match(email.text, /^Hello Mary,/);
  assert.match(email.text, /Colombo 07 library/);
  assert.match(email.text, /Sri Lanka time/);
});

test('the email falls back to a plain greeting without a name', () => {
  assert.match(buildReminderEmail(session(), undefined).text, /^Hello,/);
});
