/**
 * Ora FacePass — Demo Follow-Up Drafter
 *
 * Runs daily at 12:00 PM MT (via cron).
 * Queries GoHighLevel (GHL) for Ora FacePass demo appointments completed in
 * the last 24 hours. For each completed demo, drafts a follow-up email and
 * posts it to Slack for Dereck to review before sending.
 *
 * If no demos were completed in the last 24 hours, posts a short confirmation.
 *
 * GHL API reference: https://highlevel.stoplight.io/docs/integrations/
 */

require("dotenv").config({ path: require("path").join(__dirname, "../.env") });
const axios = require("axios");
const dayjs = require("dayjs");
const utc = require("dayjs/plugin/utc");
const timezone = require("dayjs/plugin/timezone");
const fs = require("fs");
const path = require("path");

dayjs.extend(utc);
dayjs.extend(timezone);

// ─── Config ──────────────────────────────────────────────────────────────────

const GHL_API_KEY         = process.env.GHL_API_KEY;
const GHL_LOCATION_ID     = process.env.GHL_LOCATION_ID;
const GHL_CALENDAR_ID     = process.env.GHL_CALENDAR_ID || null; // optional: filter to a specific calendar
const SLACK_WEBHOOK_URL   = process.env.SLACK_WEBHOOK_URL;
const SLACK_DERECK_USER_ID = process.env.SLACK_DERECK_USER_ID || null;
const CALENDLY_LINK       = process.env.CALENDLY_LINK || "https://calendly.com/orafacepass";

const MT_TZ    = "America/Denver";
const GHL_BASE = "https://rest.gohighlevel.com/v1";

// Run-once guard: prevents duplicate runs within this many hours.
// Cron fires via TZ=America/Denver, but this guard provides an extra safety net
// against accidental re-triggers (e.g. manual test runs close to noon).
const LOCK_WINDOW_HOURS = 4;
const LOCK_FILE = path.join(__dirname, "../logs/demo-followup-drafter.lock");

// Appointment statuses GHL uses for a completed / attended demo.
// "showed" = prospect attended; "completed" = marked done by rep.
const COMPLETED_STATUSES = new Set(["showed", "completed"]);

// ─── Run-once guard ───────────────────────────────────────────────────────────

/**
 * Returns true if the script has already run within LOCK_WINDOW_HOURS.
 * Writes/updates the lock file if it's safe to proceed.
 */
function acquireLock() {
  try {
    fs.mkdirSync(path.dirname(LOCK_FILE), { recursive: true });
    if (fs.existsSync(LOCK_FILE)) {
      const lastRun = parseInt(fs.readFileSync(LOCK_FILE, "utf8").trim(), 10);
      const hoursSince = (Date.now() - lastRun) / (1000 * 60 * 60);
      if (hoursSince < LOCK_WINDOW_HOURS) {
        return false; // already ran recently
      }
    }
    fs.writeFileSync(LOCK_FILE, String(Date.now()), "utf8");
    return true;
  } catch (err) {
    // If lock check fails for any reason, allow the run (fail open)
    console.warn("  Lock file check failed — proceeding anyway:", err.message);
    return true;
  }
}

// ─── GHL helpers ─────────────────────────────────────────────────────────────

/**
 * Build standard GHL auth headers.
 */
function ghlHeaders() {
  return {
    Authorization: `Bearer ${GHL_API_KEY}`,
    "Content-Type": "application/json",
    Version: "2021-04-15",
  };
}

/**
 * Fetch ALL appointments for a given UTC date range, handling GHL pagination.
 * GHL v1: GET /appointments/
 * Query params: locationId, startTime, endTime (ISO strings), calendarId (optional),
 *               limit (max per page), skip (offset for pagination)
 */
async function fetchAppointments(startISO, endISO) {
  const PAGE_LIMIT = 100; // GHL v1 max per page
  const all = [];
  let skip = 0;

  while (true) {
    const params = {
      locationId: GHL_LOCATION_ID,
      startTime: startISO,
      endTime: endISO,
      limit: PAGE_LIMIT,
      skip,
    };
    if (GHL_CALENDAR_ID) params.calendarId = GHL_CALENDAR_ID;

    const response = await axios.get(`${GHL_BASE}/appointments/`, {
      headers: ghlHeaders(),
      params,
    });

    // GHL returns { appointments: [...] } or { data: [...] } depending on version
    const page = (
      response.data?.appointments ??
      response.data?.data ??
      (Array.isArray(response.data) ? response.data : [])
    );

    all.push(...page);

    // Stop when we get a partial page (no more results)
    if (page.length < PAGE_LIMIT) break;
    skip += PAGE_LIMIT;
  }

  return all;
}

/**
 * Fetch a single GHL contact by ID to get name / email / company.
 */
async function fetchContact(contactId) {
  try {
    const response = await axios.get(`${GHL_BASE}/contacts/${contactId}`, {
      headers: ghlHeaders(),
    });
    return response.data?.contact ?? response.data ?? null;
  } catch {
    return null;
  }
}

// ─── Email draft builder ──────────────────────────────────────────────────────

/**
 * Build the follow-up email draft for a completed demo.
 *
 * @param {object} appt  - GHL appointment object
 * @param {object|null} contact - GHL contact object (may be null if lookup failed)
 * @returns {{ to: string, subject: string, body: string }}
 */
function buildEmailDraft(appt, contact) {
  const firstName = contact?.firstName ?? contact?.first_name ?? "there";
  const lastName  = contact?.lastName  ?? contact?.last_name  ?? "";
  const fullName  = lastName ? `${firstName} ${lastName}` : firstName;
  const email     = contact?.email ?? appt?.email ?? "(email not found — check GHL)";
  const company   = contact?.companyName ?? contact?.company_name ?? contact?.company ?? "";

  // Format the demo date in MT
  const demoDate = appt.startTime
    ? dayjs(appt.startTime).tz(MT_TZ).format("MMMM D, YYYY")
    : "your recent demo";

  const companyLine = company ? ` at ${company}` : "";

  const subject = `Next Steps — Ora FacePass Demo Follow-Up`;

  const body = `Hi ${firstName},

Thank you for taking the time to connect with us${companyLine} on ${demoDate}. It was great walking you through Ora FacePass and showing you how our frictionless facial recognition check-in can work for your team.

Based on our conversation, the next step is [INSERT AGREED NEXT STEP — e.g., a scoped pilot proposal / a technical walkthrough with your IT team / a pricing review].

I'd like to lock in some time to keep the momentum going. You can grab a spot directly on my calendar here:

${CALENDLY_LINK}

If you have any questions before we connect, feel free to reply directly to this email.

Looking forward to it.

Dereck Loero
Fractional CMO, Ora FacePass`;

  return { to: email, subject, body, firstName, fullName, demoDate };
}

// ─── Slack formatting ─────────────────────────────────────────────────────────

function escapeSlack(str) {
  return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

/**
 * Build a single Slack section block for one email draft.
 */
function buildDraftBlock(draft, index, total) {
  const header = `📧 *Draft ${index + 1} of ${total}* — To: ${escapeSlack(draft.to)}`;
  const subjectLine = `*Subject:* ${escapeSlack(draft.subject)}`;
  // Indent the body for readability in Slack
  const indentedBody = draft.body
    .split("\n")
    .map((l) => `> ${escapeSlack(l)}`)
    .join("\n");

  return [
    {
      type: "section",
      text: {
        type: "mrkdwn",
        text: `${header}\n${subjectLine}`,
      },
    },
    {
      type: "section",
      text: {
        type: "mrkdwn",
        text: indentedBody,
      },
    },
    { type: "divider" },
  ];
}

function buildSlackPayload(drafts, runDate) {
  const mention = SLACK_DERECK_USER_ID
    ? `<@${SLACK_DERECK_USER_ID}>`
    : "Dereck";

  if (drafts.length === 0) {
    return {
      text: `✅ *Ora FacePass Demo Follow-Ups — ${runDate}*\nNo demos completed in the last 24 hours. No follow-up emails needed today.`,
    };
  }

  const blocks = [
    {
      type: "header",
      text: {
        type: "plain_text",
        text: `Ora FacePass Demo Follow-Ups — ${runDate}`,
        emoji: true,
      },
    },
    {
      type: "section",
      text: {
        type: "mrkdwn",
        text:
          `Hey ${mention} — *${drafts.length} demo follow-up ${drafts.length === 1 ? "draft" : "drafts"}* from the last 24 hours.\n` +
          `*Review each draft below and send (or edit) before end of day.*\n` +
          `_Bracketed placeholders [ ] need your input before sending._`,
      },
    },
    { type: "divider" },
  ];

  drafts.forEach((draft, i) => {
    blocks.push(...buildDraftBlock(draft, i, drafts.length));
  });

  blocks.push({
    type: "context",
    elements: [
      {
        type: "mrkdwn",
        text: `_Generated ${dayjs().tz(MT_TZ).format("MMM D, YYYY h:mm A")} MT · ⚠️ DRAFT — DO NOT SEND WITHOUT REVIEW_`,
      },
    ],
  });

  return {
    blocks,
    text: `Ora FacePass Demo Follow-Ups — ${drafts.length} draft${drafts.length === 1 ? "" : "s"} ready for review`,
  };
}

async function postToSlack(payload) {
  await axios.post(SLACK_WEBHOOK_URL, payload);
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  if (!GHL_API_KEY) {
    console.error("ERROR: GHL_API_KEY is not set.");
    process.exit(1);
  }
  if (!GHL_LOCATION_ID) {
    console.error("ERROR: GHL_LOCATION_ID is not set.");
    process.exit(1);
  }
  if (!SLACK_WEBHOOK_URL) {
    console.error("ERROR: SLACK_WEBHOOK_URL is not set.");
    process.exit(1);
  }

  const now     = dayjs().tz(MT_TZ);
  const runDate = now.format("dddd, MMM D");
  console.log(`[${new Date().toISOString()}] Ora FacePass Demo Follow-Up Drafter starting…`);

  if (!acquireLock()) {
    console.log("  Already ran within the last", LOCK_WINDOW_HOURS, "hours — skipping duplicate run.");
    process.exit(0);
  }

  // 24-hour window ending now, in UTC ISO format (what GHL expects)
  const windowEnd   = now.utc();
  const windowStart = windowEnd.subtract(24, "hour");
  const startISO    = windowStart.toISOString();
  const endISO      = windowEnd.toISOString();

  console.log(`  Window: ${startISO} → ${endISO}`);

  // ── 1. Fetch appointments from GHL ─────────────────────────────────────────
  let appointments;
  try {
    appointments = await fetchAppointments(startISO, endISO);
  } catch (err) {
    console.error("Failed to fetch appointments from GHL:", err.message);
    if (err.response) {
      console.error("  Status:", err.response.status);
      console.error("  Body:", JSON.stringify(err.response.data));
    }
    process.exit(1);
  }

  if (!Array.isArray(appointments)) {
    console.error("Unexpected GHL response shape:", JSON.stringify(appointments));
    process.exit(1);
  }

  console.log(`  Fetched ${appointments.length} appointment(s) from GHL.`);

  // ── 2. Filter to completed demos ───────────────────────────────────────────
  const completedDemos = appointments.filter((appt) => {
    const status = (appt.appointmentStatus ?? appt.status ?? "").toLowerCase();
    return COMPLETED_STATUSES.has(status);
  });

  console.log(`  Completed demos: ${completedDemos.length}`);

  // ── 3. Enrich with contact data & build email drafts ───────────────────────
  const drafts = [];

  for (const appt of completedDemos) {
    const contactId = appt.contactId ?? appt.contact_id ?? null;
    let contact = null;

    if (contactId) {
      contact = await fetchContact(contactId);
    }

    const draft = buildEmailDraft(appt, contact);
    drafts.push(draft);

    console.log(
      `  Draft created for ${draft.fullName} (${draft.demoDate}) → ${draft.to}`
    );
  }

  // ── 4. Post to Slack ───────────────────────────────────────────────────────
  const payload = buildSlackPayload(drafts, runDate);

  try {
    await postToSlack(payload);
    if (drafts.length === 0) {
      console.log("  ✓ No demos found — confirmation posted to Slack.");
    } else {
      console.log(`  ✓ ${drafts.length} draft(s) posted to Slack for review.`);
    }
  } catch (err) {
    console.error("Failed to post to Slack:", err.message);
    process.exit(1);
  }
}

main();
