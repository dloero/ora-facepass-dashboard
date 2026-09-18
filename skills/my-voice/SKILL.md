---
name: my-voice
description: Write texts, DMs, emails, follow-ups, LinkedIn posts, and replies in the writer's real voice, built from their own messages instead of adjectives. Use every time the user asks to draft, reply, text, email, follow up, or "make this sound like me." Do not skip it for short messages. Short messages are where AI shows the most. On first use, run Setup to build the profile from real samples.
---

# My Voice

Goal: the reader never suspects a machine. If the draft reads clean, balanced, and polished, it is wrong.

This file has two parts. The rules are the same for everyone. The profile is yours and starts empty. The model copies your samples more than it obeys the rules, so the samples matter most.

## Mode check

Look at the Profile and Samples sections below. If either still says `[UNSET]`, run Setup first. Otherwise go to Write.

## Setup (run once, then again whenever the voice drifts)

Adjectives do not work. "Punchy and friendly" produces the same generic output for everyone. Real messages work. So collect them.

Step 1. Ask for samples. All written by the writer. None edited by AI.

- 8 or more texts, DMs, or Slack messages. Copied raw. Typos and lowercase included. These matter most.
- 3 emails the writer sent. At least one cold or sales email and one to a teammate.
- 2 examples of the writer annoyed or pushing back.
- 1 longer piece if one exists. A post, a memo, a voice note transcript.
- Target 1,500 words total. Under 800, say the profile will be thin and ask for more.

Step 2. Ask three questions.

1. Paste one message from someone else that made you cringe. What was wrong with it?
2. How do you sound when you are excited? When you are annoyed? One real example of each.
3. Who do you write to most, and what do you want them to do after reading?

Step 3. Read the samples and pull out each of these, quoting the sample as evidence:

- Sentence length. Typical, shortest, longest. Do they stack short lines or write paragraphs?
- Openers. Greeting or none. First name only. Straight to the point.
- Closers. Sign-off word. An initial. Nothing.
- Capitalization and punctuation. Lowercase in texts. Periods or not. Dashes, ellipses, exclamation points, emoji.
- Words they use often. Words that never appear even when they would fit.
- How they ask for something. A direct question. "Can you." A statement with no question mark.
- How they show excitement, frustration, and confidence.
- How they handle pushback. Concede then counter. Facts. Silence.
- What they offer instead of "happy to help." A list, an intro, a file, a call.
- Anything that breaks a rule on purpose. Keep it. Do not normalize it.

Step 4. Fill the Profile section. Every line is an instruction. "Use," "never," "always," "open with." No analysis. Never write "the writer tends to." Write "none" for a line that does not apply.

Step 5. Paste the samples into the Samples section, verbatim, grouped by channel. Never paste a generated sample. Never clean one up.

Step 6. If you can edit this file, write the filled Profile and Samples into it. If you cannot, output both sections in full for the writer to paste in.

Step 7. After the first 5 drafts, ask which lines felt like them and which did not. Update the profile. Add the drafts they approved to the samples.

## Write

1. Read the Samples section first. Match their length and rhythm before you apply any rule below.
2. Identify the channel and use its rules.
3. Open with the point. Context only if it unblocks the reader.
4. One ask per message.
5. Apply the hard bans, then the personal bans in the profile.
6. Run the self-check.
7. If the humanize-copy skill is installed, run its counting audit on the draft.
8. Output the message only.

## Hard bans (the tells, for everyone)

- Em dashes (`—`). Use a period or a comma. Exception: the samples use them.
- "I hope this finds you well," "Just wanted to," "Just checking in," "Circling back," "Reaching out," "Touching base."
- "I'd love to," "I'd be happy to," "Feel free to," "Don't hesitate to."
- "Absolutely," "Great question," "Certainly," "Of course."
- Delve, leverage (as a verb), robust, seamless, streamline, elevate, unlock, empower, game-changer, cutting-edge, navigate, landscape, journey, "at the end of the day."
- "It's not X, it's Y."
- Three adjectives in a row. Three parallel phrases in a row.
- A rhetorical question the writer then answers.
- Summary lines. "In short," "Bottom line," "To sum up."
- A motivational closer or a P.S. pep talk.
- Emoji, unless the reader used them first or the samples show them.
- Bullets in texts, DMs, or short emails.
- Headers in anything shorter than a document.
- Sentences that are all the same length. Some lines are 2 words.
- Explaining why you are saying something. Say it.
- Apologizing for being direct.
- Adding a fact the writer did not give you. A name, number, date, price, or result comes from the writer or it does not go in.

## Channel rules (defaults; the profile overrides these)

Text, DM, Slack. 1 to 4 lines. No greeting unless the relationship calls for it. Lowercase if the samples are lowercase. One ask.

Email. Subject is plain and short. Open with the point or a one-line intro. Short lines, uneven lengths. One ask at the end. Readable in 15 seconds. Sign the way the samples sign.

Sales and outbound. No hype. One offer, one ask. Sell with a specific problem the reader has, a specific thing the writer did about it, and a plain next step. Under 90 words cold. Under 50 words for a follow-up.

Reply to pushback. Concede the true part in one line. Give one fact or one attachment. One question back.

Internal or team. Directive. Outcome first. "fix the layout, don't touch the pricing, send when it's ready."

Public post. Same voice, slightly more complete sentences. First line is the point. No headers, no listicle, no "here's what I learned."

## Profile

Filled in Setup. Every line is an instruction to the model.

### Who is writing

[UNSET] Two or three sentences. Role, how they think, what they have no patience for. Written as instructions, not description. Example shape: "Founder who sells. Decides fast, writes faster. Treats the reader as competent. Zero patience for filler."

### How they write

- Sentence length: [UNSET] (example: "Mostly under 12 words. One long line when explaining. Some lines are 2 words.")
- Structure: [UNSET] (example: "Stacks thoughts on separate lines. No paragraphs in texts.")
- Openers: [UNSET] (example: "No greeting in texts. First name only in email.")
- Closers: [UNSET] (example: "Signs email with a first initial. Texts end on the ask.")
- Capitalization and punctuation: [UNSET] (example: "Lowercase in texts. Periods optional. Never an exclamation point.")
- Excitement sounds like: [UNSET]
- Frustration sounds like: [UNSET]
- Confidence sounds like: [UNSET]
- Asks for things by: [UNSET]
- Handles pushback by: [UNSET]
- Offers instead of "happy to help": [UNSET]

### Words they use

[UNSET] 10 to 20 words or phrases, quoted from the samples.

### Words they never use

[UNSET] Include the ones that would fit the topic but never appear.

### Personal bans

[UNSET] Anything the writer said makes them cringe. These add to the hard bans above.

### Rules they break on purpose

[UNSET] Keep these. Do not normalize them.

## Samples

Real messages, verbatim, grouped by channel. The model copies these more than the rules. Ten or more. Never generated, never cleaned up.

### Texts, DMs, Slack

[UNSET]

### Emails

[UNSET]

### Annoyed or pushing back

[UNSET]

### Longer piece

[UNSET]

## Self-check before output

Read the draft once and ask:

1. Would this reader suspect a machine? If yes, cut 30 percent and remove every banned word.
2. Is there a line that exists only to be polite? Delete it.
3. Is there one ask? If more than one, cut to one.
4. Does the rhythm vary? If every line is the same length, break it.
5. Did I add a summary, a sign-off pep line, or a P.S.? Delete it.
6. Did I add a fact the writer did not give me? Remove it.
7. Does it sound like the samples or like the rules? The samples win.

Output the message only. No preamble, no "here's a draft," no explanation after.
