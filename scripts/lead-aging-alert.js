/**
 * Ora FacePass — Lead Aging Alert
 *
 * Runs daily at 9 PM MT (via cron).
 * Scans Apollo.io for Ora FacePass contacts with no activity in
 * LEAD_AGING_THRESHOLD_DAYS (default 3) or more days.
 * Categorizes each lead as:
 *   • Needs Call        — has a phone number; email sent but no reply
 *   • Needs Email       — has email; no prior outreach recorded
 *   • Needs Reassignment — idle LEAD_REASSIGNMENT_THRESHOLD_DAYS+ days
 *                          OR marked as inactive / uncontactable
 * Posts a formatted action-list to a Slack webhook for Dereck to review.
 */

require("dotenv").config({ path: require("path").join(__dirname, "../.env") });
const axios = require("axios");
const dayjs = require("dayjs");
const utc = require("dayjs/plugin/utc");
const timezone = require("dayjs/plugin/timezone");

dayjs.extend(utc);
dayjs.extend(timezone);

// ─── Config ──────────────────────────────────────────────────────────────────

const APOLLO_API_KEY = process.env.APOLLO_API_KEY;
const SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL;
const SLACK_DERECK_USER_ID = process.env.SLACK_DERECK_USER_ID || null;
const AGING_DAYS = parseInt(process.env.LEAD_AGING_THRESHOLD_DAYS ?? "3", 10);
const REASSIGN_DAYS = parseInt(
  process.env.LEAD_REASSIGNMENT_THRESHOLD_DAYS ?? "30",
  10
);
// Set APOLLO_LEAD_LABEL to a label name to restrict the scan to a specific list.
// Leave blank (default) to scan all contacts in the account.
const APOLLO_LEAD_LABEL = process.env.APOLLO_LEAD_LABEL || "";
// Stop paginating once every contact on a page is older than this many days.
// Keeps runtime fast on large accounts (98K+ contacts) without missing recent leads.
const EARLY_STOP_DAYS = parseInt(process.env.LEAD_EARLY_STOP_DAYS ?? "60", 10);
const MAX_PAGES = parseInt(process.env.LEAD_MAX_PAGES ?? "20", 10);

const APOLLO_BASE = "https://api.apollo.io/v1";

// ─── Apollo helpers ───────────────────────────────────────────────────────────

/**
 * Fetch one page of contacts from Apollo.
 * Apollo contacts search: POST /contacts/search
 */
async function fetchContactPage(page = 1) {
  const payload = {
    api_key: APOLLO_API_KEY,
    page,
    per_page: 100,
    // Restrict to a named label/list when configured; otherwise scan all contacts.
    ...(APOLLO_LEAD_LABEL ? { label_names: [APOLLO_LEAD_LABEL] } : {}),
    // Sort newest-activity-first so we see recently-stale leads immediately.
    // We stop paginating once all contacts on a page are older than EARLY_STOP_DAYS.
    sort_by_field: "contact_last_activity_date",
    sort_ascending: false,
  };

  const response = await axios.post(`${APOLLO_BASE}/contacts/search`, payload, {
    headers: { "Content-Type": "application/json" },
  });

  return response.data;
}

/**
 * Pull contacts, stopping early once the page is entirely beyond EARLY_STOP_DAYS.
 * Caps at MAX_PAGES to protect against runaway pagination on very large accounts.
 */
async function fetchAllContacts() {
  const contacts = [];
  let page = 1;
  let totalPages = 1;
  const now = dayjs().tz(MT_TZ);

  do {
    const data = await fetchContactPage(page);
    const pageContacts = data.contacts ?? [];
    contacts.push(...pageContacts);
    totalPages = data.pagination?.total_pages ?? 1;

    // Early-stop: if every contact on this page is older than EARLY_STOP_DAYS,
    // anything on the next pages will be too — no point fetching further.
    const allOld = pageContacts.length > 0 && pageContacts.every((c) => {
      const raw = c.contact_last_activity_date ?? c.last_activity_date ?? c.updated_at;
      if (!raw) return true;
      return now.diff(dayjs.tz(raw, MT_TZ), "day") > EARLY_STOP_DAYS;
    });

    if (allOld) break;

    page += 1;
  } while (page <= totalPages && page <= MAX_PAGES);

  return contacts;
}

// ─── Categorization ───────────────────────────────────────────────────────────

const MT_TZ = "America/Denver";

function daysSinceActivity(contact) {
  const raw =
    contact.contact_last_activity_date ??
    contact.last_activity_date ??
    contact.updated_at;

  if (!raw) return Infinity;

  const lastActivity = dayjs.tz(raw, MT_TZ);
  const now = dayjs().tz(MT_TZ);
  return now.diff(lastActivity, "day");
}

/**
 * Determine whether a contact's last activity involved an outbound email.
 * Apollo stores activity types in contact.phone_numbers and activity metadata.
 * We approximate using the contact's latest_message_or_email_subject field and
 * email_status.
 */
function hadOutboundEmail(contact) {
  // Apollo surfaces this as email_status values like "verified", "likely_to_engage" etc.
  // A non-null email_status means we have email history.
  const emailStatus = contact.email_status;
  const hasEmailedBefore =
    emailStatus && !["unavailable", null, undefined].includes(emailStatus);

  // Also check if any sequence step has been executed (emailer_data)
  const sequenceSteps = contact.emailer_campaign_ids ?? [];
  return hasEmailedBefore || sequenceSteps.length > 0;
}

function hasPhoneNumber(contact) {
  return (
    Array.isArray(contact.phone_numbers) && contact.phone_numbers.length > 0
  );
}

function isUncontactable(contact) {
  const bad = ["bounced", "do_not_contact", "invalid", "unsubscribed"];
  return bad.includes(contact.email_status) || contact.do_not_contact === true;
}

/**
 * Returns "reassignment" | "call" | "email" | null (null = not stale)
 */
function categorize(contact) {
  const idle = daysSinceActivity(contact);

  if (idle < AGING_DAYS) return null; // still fresh

  if (idle >= REASSIGN_DAYS || isUncontactable(contact)) return "reassignment";

  if (hasPhoneNumber(contact) && hadOutboundEmail(contact)) return "call";

  return "email";
}

// ─── Slack formatting ─────────────────────────────────────────────────────────

function contactLine(contact, idleDays) {
  const name = [contact.first_name, contact.last_name].filter(Boolean).join(" ") || "Unknown";
  const company = contact.organization_name ?? contact.account?.name ?? "—";
  const phone = contact.phone_numbers?.[0]?.sanitized_number ?? "";
  const email = contact.email ?? "";
  const owner = contact.owner_name ?? contact.contact_owner?.name ?? "unassigned";
  const idleLabel = idleDays === Infinity ? "unknown" : `${idleDays}d idle`;

  const detail = [company, phone || email, `owner: ${owner}`, idleLabel]
    .filter(Boolean)
    .join(" · ");

  return `• *${name}* — ${detail}`;
}

function buildSlackMessage(groups, runDate) {
  const mention = SLACK_DERECK_USER_ID
    ? `<@${SLACK_DERECK_USER_ID}>`
    : "Dereck";

  const total =
    groups.call.length + groups.email.length + groups.reassignment.length;

  if (total === 0) {
    return {
      text: `✅ *Ora FacePass Lead Aging Alert — ${runDate}*\nNo stale leads found. All contacts have activity within the last ${AGING_DAYS} days.`,
    };
  }

  const sections = [
    {
      type: "header",
      text: {
        type: "plain_text",
        text: `📋 Ora FacePass Lead Aging Alert — ${runDate}`,
        emoji: true,
      },
    },
    {
      type: "section",
      text: {
        type: "mrkdwn",
        text: `Hey ${mention} — *${total} lead${total !== 1 ? "s" : ""}* with no activity in ${AGING_DAYS}+ days need attention:`,
      },
    },
    { type: "divider" },
  ];

  if (groups.call.length) {
    sections.push({
      type: "section",
      text: {
        type: "mrkdwn",
        text:
          `📞 *Needs Call (${groups.call.length})*\n_Email sent, no reply — follow up by phone_\n` +
          groups.call.map((c) => contactLine(c, daysSinceActivity(c))).join("\n"),
      },
    });
    sections.push({ type: "divider" });
  }

  if (groups.email.length) {
    sections.push({
      type: "section",
      text: {
        type: "mrkdwn",
        text:
          `✉️ *Needs Email (${groups.email.length})*\n_No outreach yet — send initial message_\n` +
          groups.email.map((c) => contactLine(c, daysSinceActivity(c))).join("\n"),
      },
    });
    sections.push({ type: "divider" });
  }

  if (groups.reassignment.length) {
    sections.push({
      type: "section",
      text: {
        type: "mrkdwn",
        text:
          `🔄 *Needs Reassignment (${groups.reassignment.length})*\n_Idle ${REASSIGN_DAYS}+ days or uncontactable — reassign or close_\n` +
          groups.reassignment
            .map((c) => contactLine(c, daysSinceActivity(c)))
            .join("\n"),
      },
    });
    sections.push({ type: "divider" });
  }

  sections.push({
    type: "context",
    elements: [
      {
        type: "mrkdwn",
        text: `_Generated ${dayjs().tz(MT_TZ).format("MMM D, YYYY h:mm A")} MT · Label: "${APOLLO_LEAD_LABEL}" · Aging threshold: ${AGING_DAYS}d · Reassign threshold: ${REASSIGN_DAYS}d_`,
      },
    ],
  });

  return { blocks: sections, text: `Ora FacePass Lead Aging Alert — ${total} leads need attention` };
}

async function postToSlack(payload) {
  await axios.post(SLACK_WEBHOOK_URL, payload);
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  if (!APOLLO_API_KEY) {
    console.error("ERROR: APOLLO_API_KEY is not set.");
    process.exit(1);
  }
  if (!SLACK_WEBHOOK_URL) {
    console.error("ERROR: SLACK_WEBHOOK_URL is not set.");
    process.exit(1);
  }

  console.log(
    `[${new Date().toISOString()}] Ora FacePass Lead Aging Alert starting…`
  );
  console.log(
    `  Label: "${APOLLO_LEAD_LABEL}" | Aging: ${AGING_DAYS}d | Reassign: ${REASSIGN_DAYS}d`
  );

  let contacts;
  try {
    contacts = await fetchAllContacts();
  } catch (err) {
    console.error("Failed to fetch contacts from Apollo:", err.message);
    process.exit(1);
  }

  console.log(`  Fetched ${contacts.length} contacts from Apollo.`);

  const groups = { call: [], email: [], reassignment: [] };

  for (const contact of contacts) {
    const bucket = categorize(contact);
    if (bucket) groups[bucket].push(contact);
  }

  const total =
    groups.call.length + groups.email.length + groups.reassignment.length;

  console.log(
    `  Stale leads — call: ${groups.call.length}, email: ${groups.email.length}, reassignment: ${groups.reassignment.length}`
  );

  const runDate = dayjs().tz(MT_TZ).format("dddd, MMM D");
  const payload = buildSlackMessage(groups, runDate);

  try {
    await postToSlack(payload);
    console.log(`  ✓ Slack message posted (${total} stale leads reported).`);
  } catch (err) {
    console.error("Failed to post to Slack:", err.message);
    process.exit(1);
  }
}

main();
