# G-Force Extraction — Mac Data Consolidation Protocol

Companion to `gforce_extract.zsh`. Run this on the Mac Mini, then the MacBook, then
merge the two archives.

---

## 0. One correction before you start: SIP vs. Full Disk Access

These are two different things, and the distinction matters:

| | What it protects | How you change it |
|---|---|---|
| **SIP** (System Integrity Protection) | macOS system files: `/System`, `/usr`, system binaries | Only from Recovery Mode via `csrutil disable` |
| **TCC / Full Disk Access** | *Your* data: Mail, Messages, Photos, iCloud Drive, Safari history | System Settings → Privacy & Security |

**What blocks this script is TCC, not SIP.** Everything you're looking for — Mail,
Messages, iCloud Drive, Documents — sits behind Full Disk Access. None of it is
behind SIP. **Do not disable SIP.** It buys you nothing here and leaves the machine
meaningfully less protected. Step 1 below is all the access this needs.

---

## 1. Grant Full Disk Access to Terminal

macOS 13 Ventura and later (Sonoma, Sequoia, Tahoe):

1.  Apple menu () → **System Settings**
2.  **Privacy & Security** in the sidebar → scroll down → **Full Disk Access**
3.  Find **Terminal** in the list and switch the toggle **on**.
    Not listed? Click **+**, press `⌘⇧G`, paste `/Applications/Utilities/`, select
    `Terminal.app`, click **Open**.
4.  Authenticate with Touch ID or your login password.
5.  **Quit Terminal completely — `⌘Q`, not just closing the window.** The permission
    only takes effect on a fresh launch. This is the single most common reason the
    script comes back with "Operation not permitted" everywhere.
6.  Reopen Terminal.

macOS 12 Monterey and earlier: **System Preferences → Security & Privacy → Privacy**
tab → **Full Disk Access** → click the 🔒 → **+** → add Terminal.

**Grant it to the app you actually run the script from.** If you use iTerm2, VS Code's
integrated terminal, or Warp, add *that* app — permission does not inherit. If you run
it over SSH, add `/usr/libexec/sshd-keygen-wrapper` instead.

### Verify it worked before running anything

```bash
ls ~/Library/Messages/
```

- You see `chat.db` → Full Disk Access is live. Proceed.
- `Operation not permitted` → it isn't. Repeat step 5 (the full quit is usually what's missing).

---

## 2. Make the script executable

```bash
cd ~/Downloads                      # or wherever you saved it
chmod +x gforce_extract.zsh
```

If you downloaded or AirDropped the file, macOS may have flagged it with a quarantine
attribute. Clear it:

```bash
xattr -d com.apple.quarantine gforce_extract.zsh 2>/dev/null || true
```

---

## 3. Run it

**First, a dry run.** Nothing is copied; you get the full log and manifest so you can
see what it *would* collect and how noisy the matching is:

```bash
./gforce_extract.zsh --dry-run
open ~/Desktop/GForce_Master_Archive/*/MANIFEST.csv
```

**Then the real run.** `caffeinate -i` stops the Mac from sleeping mid-scan:

```bash
caffeinate -i ./gforce_extract.zsh
```

Expect 10–60 minutes depending on drive size. Progress prints as it goes and
everything is appended to `extraction_log.txt` in real time — open a second Terminal
tab and `tail -f` it if you want to watch:

```bash
tail -f ~/Desktop/GForce_Master_Archive/*/extraction_log.txt
```

**If the results are noisy** (bare "G-Force" matches GeForce drivers, racing videos,
physics notes), re-run in strict mode — it only content-matches the full company name
and domain, while still catching any file or folder *named* after them:

```bash
./gforce_extract.zsh --strict
```

Re-runs are safe and additive. The archive is excluded from its own scan, so you can
run it as many times as you like without it eating its own output.

### Useful variations

```bash
./gforce_extract.zsh --volumes                     # include external drives in /Volumes
./gforce_extract.zsh --all-files                   # grep every file, not just known text types (slow)
./gforce_extract.zsh --root "/Volumes/Backup 2023" # scan a specific drive or Time Machine mount
./gforce_extract.zsh --keyword "GFE" --keyword "Gary Force"  # add your own terms
./gforce_extract.zsh --max-copy-mb 8000            # allow copying very large video files
./gforce_extract.zsh --help                        # every flag
```

---

## 4. What you get

```
~/Desktop/GForce_Master_Archive/
└── <Computer-Name>/                 ← per-machine, so both Macs merge cleanly
    ├── files/                       ← full original directory tree, preserved
    │   └── Users/you/Documents/...
    ├── reports/
    │   ├── messages_matches.txt     ← iMessage/SMS text mentioning the company
    │   ├── mail_envelope_matches.txt← mail subjects/senders, incl. server-only mail
    │   └── browser_matches.txt      ← visits & downloads from g-forceextraction.com
    ├── MANIFEST.csv                 ← every file: origin, why it matched, size, SHA-256
    ├── extraction_log.txt           ← timestamped record of every action
    ├── errors_and_denials.txt       ← every permission denial and read failure
    └── SUMMARY.txt                  ← counts + what still needs manual export
```

**Name collisions are structurally impossible.** Files land at their full original
path under `files/`, so `Documents/a/invoice.pdf` and `Documents/b/invoice.pdf` both
survive intact. The trade-off is deep folder nesting — use `MANIFEST.csv` (open it in
Numbers or Excel) as the index, and sort by the `modules` column to see *why* each
file was pulled.

Nothing is ever moved or deleted. Every source file is opened read-only and copied.

---

## 5. How the search works (nine passes)

| # | Pass | What it catches |
|---|---|---|
| 1 | **iCloud materialization** | Downloads cloud-only files first, so they're visible to every later pass. Without this, iCloud-evicted files are invisible zero-byte placeholders. |
| 2 | **Spotlight** (`mdfind`) | Indexed content — including *inside* PDFs, Word, Pages, and Keynote. Also `kMDItemWhereFroms`, which catches files downloaded from their site even if the contents never name them. |
| 3 | **Filename traverse** (`find -iname`) | `*g-force*`, `*gforce*`, `*g_force*`, `*g force*`, `*forceextraction*` — any extension, including hidden dirs and `~/Library` where Spotlight won't look. |
| 4 | **Folder capture** | A folder named after them → everything inside it comes along, regardless of individual filenames. |
| 5 | **Content grep** | Brute-force `grep -rIiE` across ~70 text-ish extensions: txt, md, csv, json, html, eml, plist, code, logs, vcf, ics… |
| 6 | **Office/iWork** | Unzips docx/xlsx/pptx/pages/numbers/key and greps the XML inside — catches Office files Spotlight missed or never indexed. |
| 7 | **PDF text** | `pdftotext` if available, else `strings`. |
| 8 | **Apple Mail** | `~/Library/Mail/V*` message bodies (`.emlx`), Mail attachments, Mail Downloads, plus a SQL query against Envelope Index for subjects and senders. |
| 9 | **Messages** | `~/Library/Messages/Attachments` by name and content, plus a `chat.db` query exporting every matching message with date, contact, and direction — and resolving attachments from those conversations. |
| 9b | **Browsers** | Safari / Chrome / Edge / Brave / Arc / Firefox history and downloads. Downloaded file paths from their domain get pulled into the archive directly. |

Skipped by design: `node_modules`, `.git`, Caches, DerivedData, Photos library
internals, and other regenerable churn. `~/.Trash` **is** searched.

---

## 6. Both machines

Run the identical script on each Mac. Because each archive is keyed by computer name,
you can merge them without any collision:

```bash
# On the second Mac, with the first Mac's archive on an external drive or AirDropped:
rsync -av ~/Desktop/GForce_Master_Archive/ /Volumes/YourDrive/GForce_Master_Archive/
```

To find files that exist on both machines, the `sha256` column in each `MANIFEST.csv`
gives you exact duplicate detection — identical hash means byte-identical file, so you
can safely keep one copy.

---

## 7. What this cannot reach (do these by hand)

Listed honestly so you don't assume coverage you don't have — `SUMMARY.txt` repeats
this after every run:

- **Apple Notes bodies.** Note text is gzip-compressed inside `NoteStore.sqlite`, so
  grep can't see it. Open Notes → search "G-Force" → select the results →
  **File → Export as PDF** into the archive folder. (Note *attachments* under
  `~/Library/Group Containers/group.com.apple.notes/` **are** covered.)
- **Contacts and Calendar.** Contacts → search → drag the card to a folder to export
  a `.vcf`. Calendar → File → Export.
- **Photos library assets** whose filename and metadata never mention the company.
  Search the Photos app directly and export selections.
- **Server-side-only mail.** Anything never downloaded locally (common with Gmail/IMAP
  "download recent only" settings). `reports/mail_envelope_matches.txt` shows subjects
  the index knows about; do a matching search in webmail. Also search webmail directly
  for `g-forceextraction.com`.
- **Encrypted disk images and password-protected archives.** Mount/unlock them, then
  re-run with `--root /Volumes/<mounted-name>`.
- **Time Machine backups.** Mount the backup volume and pass it explicitly:
  `./gforce_extract.zsh --root "/Volumes/Time Machine Backups"`.

---

## 8. Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `Operation not permitted` all over `errors_and_denials.txt` | Full Disk Access not active. Re-do §1, and make sure you fully **quit** Terminal (`⌘Q`) after toggling it. Verify with `ls ~/Library/Messages/`. |
| Almost no Spotlight hits | Indexing is off or incomplete. Check with `mdutil -s /`. Re-enable: `sudo mdutil -i on /`, then wait for the reindex to finish before re-running. The script warns you about this at startup. |
| `chat.db not readable` | Full Disk Access again — Messages is one of the most strongly protected stores. |
| Way too many hits | `--strict`. Bare "G-Force" also matches GeForce GPUs, racing content, and physics notes. |
| Missing something you know exists | Try `--all-files` (greps extensionless files too), and add the term you'd expect with `--keyword`. Check `errors_and_denials.txt` for a denial on that path. |
| Painfully slow | Skip the brute-force grep with `--no-content` for a first pass, lower `--max-grep-mb`, or point it at specific `--root` directories. |
| iCloud files missing | They were still downloading. The script requests them on pass 1; large libraries take time. **Re-run the script** once Finder shows iCloud Drive fully downloaded. |
| PDF hits look thin | Install a real PDF text extractor: `brew install poppler`, then re-run. Otherwise it falls back to `strings`, which misses compressed-stream PDFs. |

---

## 9. After the run

The broad-match archive will contain some unrelated personal files (anything that
happened to say "g-force"). Two practical follow-ups: skim `MANIFEST.csv` and delete
the false positives before sharing the archive with anyone, and — since this folder
now concentrates a lot of your data in one place — keep it on an encrypted volume
(FileVault, or an encrypted disk image via Disk Utility) rather than loose on the
Desktop.

Once you no longer need the access, revoking Full Disk Access from Terminal is a
one-toggle reversal of §1.
