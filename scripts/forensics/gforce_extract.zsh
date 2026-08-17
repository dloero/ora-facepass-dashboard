#!/bin/zsh
# ==============================================================================
# gforce_extract.zsh — consolidated discovery + extraction of every file on this
# Mac related to "G-Force Extraction" (g-forceextraction.com).
#
# Written portable (zsh 5.x and bash 3.2+ both run it) and defensive: it never
# aborts on a permission error, it never overwrites a file in the archive, and
# it logs the original absolute path of everything it touches.
#
# Usage:   ./gforce_extract.zsh [options]
#          ./gforce_extract.zsh --help
#
# Nothing is moved or deleted. Source files are only ever read and copied.
# ==============================================================================

# NOTE: deliberately no `set -e` / `set -u`. This script must survive hundreds of
# expected failures (locked DBs, TCC denials, dangling symlinks) and keep going.
set -o pipefail 2>/dev/null || true

# A glob that matches nothing must expand to nothing, not abort (zsh) or leak the
# literal pattern (bash). Several modules glob over optional paths (Mail/V*,
# browser profiles) that legitimately may not exist.
if [ -n "$ZSH_VERSION" ]; then
  setopt NULL_GLOB 2>/dev/null
  setopt NO_NOMATCH 2>/dev/null
elif [ -n "$BASH_VERSION" ]; then
  shopt -s nullglob 2>/dev/null
fi

SCRIPT_NAME="gforce_extract"
SCRIPT_VERSION="1.1.0"

# ------------------------------------------------------------------------------
# 1. CONFIGURATION (all overridable by flags)
# ------------------------------------------------------------------------------

DEST_ROOT="$HOME/Desktop/GForce_Master_Archive"

# Keywords fed to Spotlight and used to build filename / content patterns.
KEYWORDS=(
  "G-Force Extraction"
  "g-forceextraction.com"
  "g-forceextraction"
  "G-Force"
)

# Filename globs (case-insensitive). Covers the ways humans mangle the name.
NAME_GLOBS=(
  "*g-force*"
  "*g force*"
  "*g_force*"
  "*gforce*"
  "*forceextraction*"
)

# Content regexes (extended regex, case-insensitive).
#   BROAD  = any "g force" variant, or the bare domain stem.
#   STRICT = only the full company name / domain. Use --strict to cut noise
#            (physics "g-force", GeForce drivers, racing videos, etc.).
PATTERN_BROAD='g[[:space:]_.,-]*force|forceextraction'
PATTERN_STRICT='g[[:space:]_.,-]*force[[:space:]_.,-]*extraction|g[[:space:]_.-]*forceextraction'
PATTERN="$PATTERN_BROAD"
PATTERN_LABEL="broad"

# Roots for the brute-force traverse. ~/Library and hidden dirs are included on
# purpose — that is where Spotlight refuses to look.
ROOTS=(
  "$HOME"
  "/Users/Shared"
)

# Extra roots that are inside $HOME but worth calling out explicitly so they are
# scanned even if a caller narrows --root.
EXPLICIT_TARGETS=(
  "$HOME/Documents"
  "$HOME/Desktop"
  "$HOME/Downloads"
  "$HOME/Pictures"
  "$HOME/Movies"
  "$HOME/Music"
  "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
  "$HOME/Library/Mobile Documents"
  "$HOME/Library/Containers"
  "$HOME/Library/Group Containers"
  "$HOME/Library/Messages"
  "$HOME/Library/Mail"
  "$HOME/Library/Application Support"
  "$HOME/Library/Preferences"
  "$HOME/Developer"
  "$HOME/Projects"
  "$HOME/src"
  "$HOME/.Trash"
)

# Directory *names* pruned from the traverse: churn, caches, build output.
# Everything pruned here is either regenerable or noise, never user documents.
PRUNE_NAMES=(
  "node_modules" ".git" ".svn" ".hg" "DerivedData" "CoreSimulator"
  "Caches" "Cache" "CachedData" ".cache" ".npm" ".gradle" ".m2"
  "Xcode.app" "venv" ".venv" "__pycache__" "Homebrew" "vendor"
  "Photos Library.photoslibrary" "*.photoslibrary" "*.fcpbundle"
  "Time Machine Backups" ".Spotlight-V100" ".DocumentRevisions-V100"
  ".fseventsd" ".TemporaryItems"
)

# Absolute path prefixes never scanned and never copied.
EXCLUDE_PREFIXES=(
  "/System" "/usr" "/bin" "/sbin" "/opt/homebrew" "/Library/Developer"
  "/private/var/folders" "/private/var/db" "/Volumes/Macintosh HD - Data/System"
)

# Text-ish extensions grepped for content. Binary assets are captured by name,
# by Spotlight, and by the dedicated PDF / Office modules below.
TEXT_EXTS=(
  txt text md markdown rtf csv tsv json xml html htm eml emlx mbox
  plist yaml yml log vcf ics ini cfg conf sql js jsx ts tsx py rb sh zsh
  php java swift kt c h cpp hpp go rs cs css scss less srt vtt tex bib
  webloc url desktop mdown org note
)

# Asset extensions captured wholesale from keyword-named folders.
ASSET_EXTS=(
  pdf doc docx xls xlsx ppt pptx pages numbers key psd ai indd sketch fig
  png jpg jpeg heic heif gif tiff tif bmp webp svg eps mp4 mov m4v avi mp3
  m4a wav zip tar gz 7z rar dmg msg oft eml emlx numbers-tef
)

MAX_GREP_MB=64        # do not grep files larger than this
MAX_COPY_MB=2048      # do not copy files larger than this (logged instead)
DO_SPOTLIGHT=1
DO_NAMES=1
DO_CONTENT=1
DO_OFFICE=1
DO_PDF=1
DO_MAIL=1
DO_MESSAGES=1
DO_BROWSERS=1
DO_ICLOUD=1
DO_FOLDERS=1
DO_HASH=1
DO_VOLUMES=0
ALL_FILES=0
DRY_RUN=0
QUIET=0

# ------------------------------------------------------------------------------
# 2. ARGUMENT PARSING
# ------------------------------------------------------------------------------

print_help() {
  cat <<'EOF'
gforce_extract.zsh — find and consolidate every G-Force Extraction file on this Mac.

USAGE
  ./gforce_extract.zsh [options]

OPTIONS
  --dest DIR         Archive destination (default: ~/Desktop/GForce_Master_Archive)
  --root DIR         Add a scan root. Repeatable. Replaces defaults on first use.
  --keyword STR      Add a keyword. Repeatable. Replaces defaults on first use.
  --strict           Narrow CONTENT matching to the full company name / domain
                     (cuts GeForce / physics-g-force noise). Filename and folder
                     matching stay broad either way.
  --broad            Content-match any "g force" variant (default).
  --volumes          Also scan mounted volumes under /Volumes (external drives).
  --all-files        Content-grep every file under the size cap, not just known
                     text extensions. Much slower, catches extensionless notes.
  --max-grep-mb N    Skip content-grep above N MB (default 64).
  --max-copy-mb N    Skip copying above N MB (default 2048; still logged).
  --dry-run          Discover and log everything, copy nothing.
  --no-hash          Skip SHA-256 in the manifest (faster).
  --no-spotlight     Disable the mdfind module.
  --no-content       Disable the brute-force grep module.
  --no-mail          Disable the Mail module.
  --no-messages      Disable the Messages module.
  --no-browsers      Disable the browser-history module.
  --quiet            Log to file only, minimal console output.
  -h, --help         This text.

EXIT CODES
  0 success (with or without hits)   2 bad usage   130 interrupted
EOF
}

user_roots=()
user_keywords=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dest)         DEST_ROOT="$2"; shift 2 ;;
    --root)         user_roots+=("$2"); shift 2 ;;
    --keyword)      user_keywords+=("$2"); shift 2 ;;
    --strict)       PATTERN="$PATTERN_STRICT"; PATTERN_LABEL="strict"; shift ;;
    --broad)        PATTERN="$PATTERN_BROAD";  PATTERN_LABEL="broad";  shift ;;
    --volumes)      DO_VOLUMES=1; shift ;;
    --all-files)    ALL_FILES=1; shift ;;
    --max-grep-mb)  MAX_GREP_MB="$2"; shift 2 ;;
    --max-copy-mb)  MAX_COPY_MB="$2"; shift 2 ;;
    --dry-run)      DRY_RUN=1; shift ;;
    --no-hash)      DO_HASH=0; shift ;;
    --no-spotlight) DO_SPOTLIGHT=0; shift ;;
    --no-content)   DO_CONTENT=0; shift ;;
    --no-mail)      DO_MAIL=0; shift ;;
    --no-messages)  DO_MESSAGES=0; shift ;;
    --no-browsers)  DO_BROWSERS=0; shift ;;
    --quiet)        QUIET=1; shift ;;
    -h|--help)      print_help; exit 0 ;;
    *) echo "Unknown option: $1" >&2; print_help >&2; exit 2 ;;
  esac
done

if [ ${#user_roots[@]} -gt 0 ]; then ROOTS=("${user_roots[@]}"); fi
if [ ${#user_keywords[@]} -gt 0 ]; then KEYWORDS=("${user_keywords[@]}"); fi
if [ "$DO_VOLUMES" -eq 1 ] && [ -d /Volumes ]; then ROOTS+=("/Volumes"); fi

# ------------------------------------------------------------------------------
# 3. ARCHIVE LAYOUT + LOGGING
# ------------------------------------------------------------------------------

if command -v scutil >/dev/null 2>&1; then
  MACHINE="$(scutil --get ComputerName 2>/dev/null || hostname)"
else
  MACHINE="$(hostname)"
fi
# Sanitize into a safe directory component.
MACHINE="$(printf '%s' "$MACHINE" | tr -cs 'A-Za-z0-9._-' '_' | sed 's/_*$//')"
[ -n "$MACHINE" ] || MACHINE="unknown-mac"

RUN_STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="$DEST_ROOT/$MACHINE"
FILES_DIR="$ARCHIVE/files"
REPORTS_DIR="$ARCHIVE/reports"
LOG="$ARCHIVE/extraction_log.txt"
ERRLOG="$ARCHIVE/errors_and_denials.txt"
MANIFEST="$ARCHIVE/MANIFEST.csv"
SUMMARY="$ARCHIVE/SUMMARY.txt"

mkdir -p "$FILES_DIR" "$REPORTS_DIR" || {
  echo "FATAL: cannot create archive at $ARCHIVE" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gforce.XXXXXX")" || { echo "FATAL: no temp dir" >&2; exit 1; }
HITS_RAW="$WORK/hits.tsv"
: > "$HITS_RAW"

# The archive itself must never be scanned, or every re-run doubles the archive.
EXCLUDE_PREFIXES+=("$DEST_ROOT")

cleanup() { rm -rf "$WORK" 2>/dev/null; }
on_interrupt() {
  log "!! Interrupted — writing partial results."
  finalize 130
}
trap cleanup EXIT
trap on_interrupt INT TERM

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log()  { printf '[%s] %s\n' "$(ts)" "$*" >> "$LOG";  [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }
logf() { printf '[%s] %s\n' "$(ts)" "$*" >> "$LOG"; }                    # file only
err()  { printf '[%s] %s\n' "$(ts)" "$*" >> "$ERRLOG"; logf "ERROR: $*"; }

# Every command that can hit a TCC / permission wall routes stderr here, so
# "Operation not permitted" and "Permission denied" land in errors_and_denials.txt
# instead of scrolling past. Nothing is silently swallowed.
capture_errs() { sed "s|^|[$(ts)] |" >> "$ERRLOG"; }

# ------------------------------------------------------------------------------
# 4. HELPERS
# ------------------------------------------------------------------------------

is_excluded() {
  local p="$1" pre
  for pre in "${EXCLUDE_PREFIXES[@]}"; do
    case "$p" in "$pre"/*|"$pre") return 0 ;; esac
  done
  return 1
}

# record <module> <path>
record() {
  local module="$1" hit_path="$2"
  [ -n "$hit_path" ] || return 0
  case "$hit_path" in /*) ;; *) return 0 ;; esac
  is_excluded "$hit_path" && return 0
  if [ ! -f "$hit_path" ]; then
    # A dangling symlink is a finding in its own right: it names a file that used
    # to exist. Log it so it is visible rather than quietly dropped.
    [ -L "$hit_path" ] && err "matched but unresolvable (broken symlink): $hit_path -> $(readlink "$hit_path" 2>/dev/null)"
    return 0
  fi
  printf '%s\t%s\n' "$module" "$hit_path" >> "$HITS_RAW"
}

# Consume a NUL-delimited stream on stdin and record each path.
# Paths containing a literal newline cannot survive this and are reported as
# unresolvable in errors_and_denials.txt rather than being dropped silently.
record_stream() {
  local module="$1" p
  tr '\0' '\n' | while IFS= read -r p; do
    [ -n "$p" ] || continue
    if [ -e "$p" ] || [ -L "$p" ]; then
      record "$module" "$p"
    else
      case "$p" in /*) err "unresolvable path from $module (embedded newline in filename?): $p" ;; esac
    fi
  done
}

# find(1) prune expression, shared by every traverse.
build_prune_args() {
  PRUNE_ARGS=()
  local n first=1
  PRUNE_ARGS+=("(")
  for n in "${PRUNE_NAMES[@]}"; do
    if [ $first -eq 1 ]; then first=0; else PRUNE_ARGS+=("-o"); fi
    PRUNE_ARGS+=("-name" "$n")
  done
  for n in "${EXCLUDE_PREFIXES[@]}"; do
    PRUNE_ARGS+=("-o" "-path" "$n")
  done
  PRUNE_ARGS+=(")" "-prune" "-o")
}
build_prune_args

existing_roots() {
  local r candidates=() keep other nested
  for r in "${ROOTS[@]}" "${EXPLICIT_TARGETS[@]}"; do
    [ -d "$r" ] || continue
    is_excluded "$r" && continue
    # drop exact duplicates
    nested=0
    for other in "${candidates[@]}"; do
      [ "$r" = "$other" ] && { nested=1; break; }
    done
    [ "$nested" -eq 1 ] || candidates+=("$r")
  done

  # Drop any root already contained in another root. $HOME covers Documents,
  # Desktop, Library and friends, so without this every file under $HOME gets
  # traversed a dozen times — same results, many times the wall clock.
  SCAN_ROOTS=()
  for keep in "${candidates[@]}"; do
    nested=0
    for other in "${candidates[@]}"; do
      [ "$keep" = "$other" ] && continue
      case "$keep" in "$other"/*) nested=1; break ;; esac
    done
    [ "$nested" -eq 1 ] || SCAN_ROOTS+=("$keep")
  done
}
existing_roots

sql_escape() { printf '%s' "$1" | sed "s/'/''/g"; }

# Build a SQL LIKE predicate over a column for all keywords.
like_clause() {
  local col="$1" kw first=1 out=""
  for kw in "${KEYWORDS[@]}"; do
    local esc; esc="$(sql_escape "$kw")"
    if [ $first -eq 1 ]; then first=0; else out="$out OR "; fi
    out="$out$col LIKE '%$esc%'"
  done
  # Also match the compact spellings.
  out="$out OR $col LIKE '%gforce%' OR $col LIKE '%forceextraction%'"
  printf '%s' "$out"
}

# Copy a live SQLite DB (plus WAL/SHM) somewhere writable before querying, so a
# lock held by a running app cannot make the query fail or corrupt anything.
snapshot_db() {
  local src="$1" name="$2" dst="$WORK/$name.sqlite"
  [ -r "$src" ] || return 1
  cp "$src" "$dst" 2>>"$ERRLOG" || return 1
  [ -r "$src-wal" ] && cp "$src-wal" "$dst-wal" 2>/dev/null
  [ -r "$src-shm" ] && cp "$src-shm" "$dst-shm" 2>/dev/null
  printf '%s' "$dst"
}

# BSD stat (macOS) and GNU stat (Linux, if you ever run this on a backup server)
# take incompatible flags, and GNU's -f means something else entirely. Decide once.
if [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then STAT_FLAVOR="bsd"; else STAT_FLAVOR="gnu"; fi

human_bytes() {
  local b="$1"
  if [ "$b" -ge 1073741824 ] 2>/dev/null; then printf '%s GB' "$((b/1073741824))"
  elif [ "$b" -ge 1048576 ] 2>/dev/null; then printf '%s MB' "$((b/1048576))"
  elif [ "$b" -ge 1024 ] 2>/dev/null; then printf '%s KB' "$((b/1024))"
  else printf '%s B' "$b"; fi
}

file_size() {
  local sz=""
  if [ "$STAT_FLAVOR" = "bsd" ]; then sz="$(stat -f '%z' "$1" 2>/dev/null)"
  else sz="$(stat -c '%s' "$1" 2>/dev/null)"; fi
  case "$sz" in ''|*[!0-9]*) sz="$(wc -c < "$1" 2>/dev/null | tr -d ' ')" ;; esac
  case "$sz" in ''|*[!0-9]*) sz=0 ;; esac
  printf '%s' "$sz"
}

file_mtime() {
  if [ "$STAT_FLAVOR" = "bsd" ]; then
    stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$1" 2>/dev/null | tr -d '\n'
  else
    stat -c '%y' "$1" 2>/dev/null | cut -d. -f1 | tr -d '\n'
  fi
}

hash_file() {
  [ "$DO_HASH" -eq 1 ] || { printf ''; return 0; }
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" 2>/dev/null | awk '{print $1}'
  fi
}

# Quote for CSV: double the quotes, and flatten any stray newline/CR so one record
# can never split into two rows in Excel or Numbers.
csv_field() { printf '"%s"' "$(printf '%s' "$1" | tr '\r\n' '  ' | sed 's/"/""/g')"; }

# ------------------------------------------------------------------------------
# 5. SEARCH MODULES
# ------------------------------------------------------------------------------

module_spotlight() {
  [ "$DO_SPOTLIGHT" -eq 1 ] || return 0
  command -v mdfind >/dev/null 2>&1 || { logf "mdfind unavailable, skipping Spotlight"; return 0; }
  log "== [1/9] Spotlight metadata search (mdfind)"

  if command -v mdutil >/dev/null 2>&1; then
    local idx; idx="$(mdutil -s / 2>/dev/null | tr -d '\n')"
    logf "Spotlight index state: $idx"
    case "$idx" in
      *"disabled"*|*"No index"*)
        log "   !! Spotlight indexing looks DISABLED on /. Content hits will be"
        log "      thin until you run:  sudo mdutil -i on /   (then wait for reindex)."
        ;;
    esac
  fi

  local kw
  for kw in "${KEYWORDS[@]}"; do
    logf "mdfind full-text: $kw"
    mdfind -0 "$kw" 2>>"$ERRLOG" | record_stream "spotlight:content"
    logf "mdfind filename: $kw"
    mdfind -0 -name "$kw" 2>>"$ERRLOG" | record_stream "spotlight:name"
  done

  # Files downloaded from the company's site carry the URL in kMDItemWhereFroms
  # even when their contents never mention the name.
  mdfind -0 "kMDItemWhereFroms == '*forceextraction*'c" 2>>"$ERRLOG" \
    | record_stream "spotlight:downloaded-from"
  mdfind -0 "kMDItemWhereFroms == '*g-force*'c" 2>>"$ERRLOG" \
    | record_stream "spotlight:downloaded-from"
}

module_names() {
  [ "$DO_NAMES" -eq 1 ] || return 0
  log "== [2/9] Filename traverse (find -iname, includes hidden dirs)"
  local root g name_args first=1
  name_args=("(")
  for g in "${NAME_GLOBS[@]}"; do
    if [ $first -eq 1 ]; then first=0; else name_args+=("-o"); fi
    name_args+=("-iname" "$g")
  done
  name_args+=(")")

  for root in "${SCAN_ROOTS[@]}"; do
    logf "find names in: $root"
    find "$root" "${PRUNE_ARGS[@]}" -type f "${name_args[@]}" -print0 \
      2> >(capture_errs) | record_stream "filename"
  done
}

module_folders() {
  [ "$DO_FOLDERS" -eq 1 ] || return 0
  log "== [3/9] Keyword-named folder capture (grab the whole folder)"
  local root g dir_args first=1
  dir_args=("(")
  for g in "${NAME_GLOBS[@]}"; do
    if [ $first -eq 1 ]; then first=0; else dir_args+=("-o"); fi
    dir_args+=("-iname" "$g")
  done
  dir_args+=(")")

  local d
  for root in "${SCAN_ROOTS[@]}"; do
    find "$root" "${PRUNE_ARGS[@]}" -type d "${dir_args[@]}" -print0 2> >(capture_errs) \
      | tr '\0' '\n' | while IFS= read -r d; do
          [ -d "$d" ] || continue
          is_excluded "$d" && continue
          logf "folder hit, capturing contents: $d"
          find "$d" -type f -size "-${MAX_COPY_MB}M" -print0 2> >(capture_errs) \
            | record_stream "folder:$(basename "$d")"
        done
  done
}

# Build the candidate list for content grepping into $WORK/candidates.nul
build_content_candidates() {
  local root ext ext_args first=1
  : > "$WORK/candidates.nul"

  if [ "$ALL_FILES" -eq 1 ]; then
    for root in "${SCAN_ROOTS[@]}"; do
      find "$root" "${PRUNE_ARGS[@]}" -type f -size "-${MAX_GREP_MB}M" -print0 \
        2> >(capture_errs) >> "$WORK/candidates.nul"
    done
    return 0
  fi

  ext_args=("(")
  for ext in "${TEXT_EXTS[@]}"; do
    if [ $first -eq 1 ]; then first=0; else ext_args+=("-o"); fi
    ext_args+=("-iname" "*.$ext")
  done
  ext_args+=(")")

  for root in "${SCAN_ROOTS[@]}"; do
    find "$root" "${PRUNE_ARGS[@]}" -type f -size "-${MAX_GREP_MB}M" "${ext_args[@]}" -print0 \
      2> >(capture_errs) >> "$WORK/candidates.nul"
  done
}

module_content() {
  [ "$DO_CONTENT" -eq 1 ] || return 0
  log "== [4/9] Brute-force content grep (pattern: $PATTERN_LABEL)"
  build_content_candidates
  local n; n="$(tr -dc '\0' < "$WORK/candidates.nul" | wc -c | tr -d ' ')"
  log "   candidates: $n files (<= ${MAX_GREP_MB}MB each)"
  [ -s "$WORK/candidates.nul" ] || { log "   nothing to grep"; return 0; }
  # -I skips binaries, -l lists names only, -E extended regex, -i case-insensitive.
  xargs -0 -n 200 grep -l -I -i -E -e "$PATTERN" -- < "$WORK/candidates.nul" \
    2> >(capture_errs) | tr '\n' '\0' | record_stream "content:text"
}

module_office() {
  [ "$DO_OFFICE" -eq 1 ] || return 0
  command -v unzip >/dev/null 2>&1 || { logf "unzip unavailable, skipping OOXML"; return 0; }
  log "== [5/9] Office/iWork container content scan (docx, xlsx, pptx, pages, key, numbers)"
  local root f
  for root in "${SCAN_ROOTS[@]}"; do
    find "$root" "${PRUNE_ARGS[@]}" -type f -size "-${MAX_GREP_MB}M" \
      \( -iname '*.docx' -o -iname '*.xlsx' -o -iname '*.pptx' \
         -o -iname '*.pages' -o -iname '*.numbers' -o -iname '*.key' \
         -o -iname '*.odt' -o -iname '*.ods' \) -print0 2> >(capture_errs) \
    | tr '\0' '\n' | while IFS= read -r f; do
        [ -f "$f" ] || continue
        # Stream the archive members through grep; -p writes members to stdout.
        if unzip -p "$f" 2>/dev/null | tr -d '\000' | grep -q -i -E -e "$PATTERN" 2>/dev/null; then
          record "content:office" "$f"
          logf "office hit: $f"
        fi
      done
  done
}

module_pdf() {
  [ "$DO_PDF" -eq 1 ] || return 0
  log "== [6/9] PDF text scan"
  local extractor=""
  if command -v pdftotext >/dev/null 2>&1; then extractor="pdftotext"
  elif command -v mdimport >/dev/null 2>&1; then extractor="strings"
  else extractor="strings"; fi
  logf "PDF extractor: $extractor"
  [ "$extractor" = "strings" ] && log "   note: pdftotext not installed — falling back to 'strings',"
  [ "$extractor" = "strings" ] && log "         which misses compressed-stream PDFs. Spotlight covers those."
  [ "$extractor" = "strings" ] && log "         For full coverage: brew install poppler, then re-run."

  local root f
  for root in "${SCAN_ROOTS[@]}"; do
    find "$root" "${PRUNE_ARGS[@]}" -type f -size "-${MAX_GREP_MB}M" -iname '*.pdf' -print0 \
      2> >(capture_errs) | tr '\0' '\n' | while IFS= read -r f; do
        [ -f "$f" ] || continue
        if [ "$extractor" = "pdftotext" ]; then
          if pdftotext -q "$f" - 2>/dev/null | grep -q -i -E -e "$PATTERN"; then
            record "content:pdf" "$f"; logf "pdf hit: $f"
          fi
        else
          if strings "$f" 2>/dev/null | grep -q -i -E -e "$PATTERN"; then
            record "content:pdf" "$f"; logf "pdf hit: $f"
          fi
        fi
      done
  done
}

module_mail() {
  [ "$DO_MAIL" -eq 1 ] || return 0
  log "== [7/9] Apple Mail (~/Library/Mail/V*)"
  local mailroot found=0 v
  for v in "$HOME/Library/Mail"/V*; do
    [ -d "$v" ] || continue
    found=1
    log "   Mail store: $v"
    # Message bodies (.emlx / .partial.emlx) are plain text with a length prefix,
    # so grep works directly on them.
    find "$v" -type f \( -iname '*.emlx' -o -iname '*.eml' -o -iname '*.mbox' \
        -o -iname '*.partial.emlx' \) -size "-${MAX_GREP_MB}M" -print0 2> >(capture_errs) \
      | xargs -0 -n 200 grep -l -I -i -E -e "$PATTERN" -- 2> >(capture_errs) \
      | tr '\n' '\0' | record_stream "mail:message"

    # Mail attachments live beside the messages; capture keyword-named ones too.
    find "$v" -type d -iname 'Attachments' -print0 2> >(capture_errs) \
      | tr '\0' '\n' | while IFS= read -r a; do
          find "$a" -type f -print0 2> >(capture_errs) \
            | xargs -0 -n 200 grep -l -I -i -E -e "$PATTERN" -- 2>/dev/null \
            | tr '\n' '\0' | record_stream "mail:attachment-content"
        done
  done

  if [ "$found" -eq 0 ]; then
    log "   No ~/Library/Mail/V* store found (Mail.app may not be configured on this Mac)."
  fi

  # Envelope Index: subject/sender search, useful even when bodies are on the server.
  if command -v sqlite3 >/dev/null 2>&1; then
    local idx
    for idx in "$HOME/Library/Mail"/V*/MailData/Envelope\ Index; do
      [ -r "$idx" ] || continue
      local snap; snap="$(snapshot_db "$idx" "envelope")" || continue
      local out="$REPORTS_DIR/mail_envelope_matches.txt"
      {
        echo "# Apple Mail Envelope Index matches — $idx"
        echo "# columns: date | sender | subject"
        sqlite3 -readonly -separator ' | ' "$snap" "
          SELECT datetime(m.date_sent + 978307200,'unixepoch','localtime'),
                 COALESCE(a.address,''), COALESCE(s.subject,'')
          FROM messages m
          LEFT JOIN subjects  s ON m.subject = s.ROWID
          LEFT JOIN addresses a ON m.sender  = a.ROWID
          WHERE $(like_clause "s.subject") OR $(like_clause "a.address")
          ORDER BY m.date_sent DESC;" 2>&1
      } >> "$out"
      log "   Envelope Index queried -> reports/mail_envelope_matches.txt"
    done
  fi

  # Mail Downloads (attachments opened/saved by Mail).
  if [ -d "$HOME/Library/Containers/com.apple.mail/Data/Library/Mail Downloads" ]; then
    find "$HOME/Library/Containers/com.apple.mail/Data/Library/Mail Downloads" -type f -print0 \
      2> >(capture_errs) | record_stream "mail:downloads"
  fi
}

module_messages() {
  [ "$DO_MESSAGES" -eq 1 ] || return 0
  log "== [8/9] Messages (~/Library/Messages)"

  if [ -d "$HOME/Library/Messages/Attachments" ]; then
    # Attachment filenames are meaningful; contents of text-ish ones too.
    local g name_args first=1
    name_args=("(")
    for g in "${NAME_GLOBS[@]}"; do
      if [ $first -eq 1 ]; then first=0; else name_args+=("-o"); fi
      name_args+=("-iname" "$g")
    done
    name_args+=(")")
    find "$HOME/Library/Messages/Attachments" -type f "${name_args[@]}" -print0 \
      2> >(capture_errs) | record_stream "messages:attachment-name"
    find "$HOME/Library/Messages/Attachments" -type f -size "-${MAX_GREP_MB}M" -print0 \
      2> >(capture_errs) | xargs -0 -n 200 grep -l -I -i -E -e "$PATTERN" -- 2>/dev/null \
      | tr '\n' '\0' | record_stream "messages:attachment-content"
  else
    log "   ~/Library/Messages/Attachments not readable — check Full Disk Access."
  fi

  if command -v sqlite3 >/dev/null 2>&1 && [ -r "$HOME/Library/Messages/chat.db" ]; then
    local snap; snap="$(snapshot_db "$HOME/Library/Messages/chat.db" "chat")"
    if [ -n "$snap" ]; then
      local out="$REPORTS_DIR/messages_matches.txt"
      {
        echo "# Messages (iMessage/SMS) containing the keywords"
        echo "# columns: date | contact | direction | text"
        sqlite3 -readonly -separator ' | ' "$snap" "
          SELECT datetime(m.date/1000000000 + 978307200,'unixepoch','localtime'),
                 COALESCE(h.id,'(unknown)'),
                 CASE m.is_from_me WHEN 1 THEN 'sent' ELSE 'received' END,
                 REPLACE(COALESCE(m.text, CAST(m.attributedBody AS TEXT)), char(10), ' ')
          FROM message m LEFT JOIN handle h ON m.handle_id = h.ROWID
          WHERE $(like_clause "m.text")
             OR $(like_clause "CAST(m.attributedBody AS TEXT)")
          ORDER BY m.date DESC;" 2>&1
      } >> "$out"
      log "   chat.db queried -> reports/messages_matches.txt"

      # Attachments belonging to matching conversations, resolved to real paths.
      sqlite3 -readonly "$snap" "
        SELECT DISTINCT att.filename
        FROM message m
        JOIN message_attachment_join maj ON maj.message_id = m.ROWID
        JOIN attachment att ON att.ROWID = maj.attachment_id
        WHERE $(like_clause "m.text")
           OR $(like_clause "CAST(m.attributedBody AS TEXT)")
           OR $(like_clause "att.filename");" 2>>"$ERRLOG" \
      | while IFS= read -r ap; do
          [ -n "$ap" ] || continue
          case "$ap" in "~"*) ap="$HOME${ap#\~}" ;; esac
          record "messages:attachment-linked" "$ap"
        done
    fi
  else
    log "   chat.db not readable — Full Disk Access required for Messages."
  fi
}

module_browsers() {
  [ "$DO_BROWSERS" -eq 1 ] || return 0
  command -v sqlite3 >/dev/null 2>&1 || return 0
  log "== [9/9] Browser history + downloads (URLs and downloaded file paths)"
  local out="$REPORTS_DIR/browser_matches.txt"

  # Safari
  if [ -r "$HOME/Library/Safari/History.db" ]; then
    local snap; snap="$(snapshot_db "$HOME/Library/Safari/History.db" "safari")"
    if [ -n "$snap" ]; then
      {
        echo "## Safari history"
        sqlite3 -readonly -separator ' | ' "$snap" "
          SELECT datetime(v.visit_time + 978307200,'unixepoch','localtime'),
                 COALESCE(v.title,''), i.url
          FROM history_items i JOIN history_visits v ON v.history_item = i.id
          WHERE $(like_clause "i.url") OR $(like_clause "v.title")
          ORDER BY v.visit_time DESC;" 2>&1
      } >> "$out"
    fi
  fi
  if [ -r "$HOME/Library/Safari/Downloads.plist" ] && command -v plutil >/dev/null 2>&1; then
    {
      echo "## Safari downloads referencing the keywords"
      plutil -convert xml1 -o - "$HOME/Library/Safari/Downloads.plist" 2>/dev/null \
        | grep -i -E -B2 -A2 -e "$PATTERN"
    } >> "$out"
  fi

  # Chromium family + Firefox
  local hist
  for hist in \
    "$HOME/Library/Application Support/Google/Chrome"/*/History \
    "$HOME/Library/Application Support/Microsoft Edge"/*/History \
    "$HOME/Library/Application Support/BraveSoftware/Brave-Browser"/*/History \
    "$HOME/Library/Application Support/Arc/User Data"/*/History
  do
    [ -r "$hist" ] || continue
    local snap; snap="$(snapshot_db "$hist" "chromium-$(basename "$(dirname "$hist")")")"
    [ -n "$snap" ] || continue
    {
      echo "## $hist"
      sqlite3 -readonly -separator ' | ' "$snap" "
        SELECT datetime(last_visit_time/1000000 - 11644473600,'unixepoch','localtime'),
               COALESCE(title,''), url
        FROM urls WHERE $(like_clause "url") OR $(like_clause "title")
        ORDER BY last_visit_time DESC;" 2>&1
      echo "## downloads"
      sqlite3 -readonly -separator ' | ' "$snap" "
        SELECT target_path, COALESCE(tab_url,'') FROM downloads
        WHERE $(like_clause "target_path") OR $(like_clause "tab_url");" 2>&1
    } >> "$out"
    # A file downloaded from their site is relevant even if its bytes never
    # mention the name — pull the local paths straight into the archive.
    sqlite3 -readonly "$snap" "
      SELECT target_path FROM downloads
      WHERE $(like_clause "target_path") OR $(like_clause "tab_url");" 2>/dev/null \
    | while IFS= read -r dp; do record "browser:download" "$dp"; done
  done

  local places
  for places in "$HOME/Library/Application Support/Firefox/Profiles"/*/places.sqlite; do
    [ -r "$places" ] || continue
    local snap; snap="$(snapshot_db "$places" "firefox-$(basename "$(dirname "$places")")")"
    [ -n "$snap" ] || continue
    {
      echo "## $places"
      sqlite3 -readonly -separator ' | ' "$snap" "
        SELECT datetime(last_visit_date/1000000,'unixepoch','localtime'),
               COALESCE(title,''), url
        FROM moz_places WHERE $(like_clause "url") OR $(like_clause "title")
        ORDER BY last_visit_date DESC;" 2>&1
    } >> "$out"
  done

  [ -s "$out" ] && log "   browser findings -> reports/browser_matches.txt"
}

module_icloud() {
  [ "$DO_ICLOUD" -eq 1 ] || return 0
  local ic="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
  [ -d "$ic" ] || { log "== iCloud Drive not present at $ic"; return 0; }
  log "== iCloud Drive: materializing evicted (cloud-only) files"
  # Evicted files exist locally only as zero-byte .icloud placeholders. Without
  # this pass, iCloud content is invisible to both grep and the copy stage.
  local placeholders=0 p base dir real
  find "$HOME/Library/Mobile Documents" -type f -name '.*.icloud' -print0 2> >(capture_errs) \
    | tr '\0' '\n' | while IFS= read -r p; do
        dir="$(dirname "$p")"; base="$(basename "$p")"
        base="${base#.}"; real="$dir/${base%.icloud}"
        if command -v brctl >/dev/null 2>&1; then
          brctl download "$real" 2>>"$ERRLOG"
        fi
        # Touching the file also nudges the daemon to fetch it.
        cat "$real" > /dev/null 2>>"$ERRLOG"
        printf 'x'
      done > "$WORK/icloud_count" 2>/dev/null
  placeholders="$(wc -c < "$WORK/icloud_count" 2>/dev/null | tr -d ' ')"
  [ -n "$placeholders" ] || placeholders=0
  if [ "$placeholders" -gt 0 ]; then
    log "   requested download of $placeholders cloud-only file(s)."
    log "   Large libraries may still be downloading; re-run this script afterwards"
    log "   to catch anything that had not finished materializing."
  else
    log "   no cloud-only placeholders found (everything is already local)."
  fi
}

# ------------------------------------------------------------------------------
# 6. COPY + MANIFEST
# ------------------------------------------------------------------------------

copied=0; skipped_big=0; failed=0; total_bytes=0

consolidate() {
  log "== Consolidating results"
  # Collapse duplicates: one row per path, modules joined with ';'.
  sort -t "$(printf '\t')" -k2,2 -k1,1 "$HITS_RAW" 2>/dev/null \
    | awk -F'\t' '
        {
          if (NR == 1 || $2 != prev) {
            if (NR > 1) print prev "\t" mods
            prev = $2; mods = $1
            split("", seen); seen[$1] = 1
          } else if (!($1 in seen)) {
            seen[$1] = 1; mods = mods ";" $1
          }
        }
        END { if (NR > 0) print prev "\t" mods }' \
    > "$WORK/hits.dedup.tsv"

  local unique; unique="$(wc -l < "$WORK/hits.dedup.tsv" | tr -d ' ')"
  log "   unique files matched: $unique"

  printf 'source_path,modules,size_bytes,modified,sha256,archived_path,status\n' > "$MANIFEST"

  local src mods size mtime sha rel destdir destpath outcome
  while IFS="$(printf '\t')" read -r src mods; do
    [ -n "$src" ] || continue
    [ -f "$src" ] || { err "vanished before copy: $src"; continue; }

    size="$(file_size "$src")"; [ -n "$size" ] || size=0
    mtime="$(file_mtime "$src")"
    rel="${src#/}"
    destpath="$FILES_DIR/$rel"
    destdir="$(dirname "$destpath")"
    outcome="copied"
    sha=""

    if [ "$size" -gt $((MAX_COPY_MB * 1048576)) ] 2>/dev/null; then
      outcome="skipped-too-large($(human_bytes "$size"))"
      skipped_big=$((skipped_big + 1))
      logf "SKIP (size) $src [$(human_bytes "$size")]"
    elif [ "$DRY_RUN" -eq 1 ]; then
      outcome="dry-run"
      logf "DRY-RUN would copy: $src"
    else
      if ! mkdir -p "$destdir" 2>>"$ERRLOG"; then
        outcome="failed-mkdir"; failed=$((failed + 1))
        err "mkdir failed for $destdir (source: $src)"
      else
        # ditto preserves extended attributes, resource forks and ACLs; cp -p is
        # the fallback for non-macOS. Destination mirrors the full original tree,
        # so two files with the same name can never collide.
        if command -v ditto >/dev/null 2>&1; then
          ditto "$src" "$destpath" 2>>"$ERRLOG"
        else
          cp -p "$src" "$destpath" 2>>"$ERRLOG"
        fi
        if [ -f "$destpath" ]; then
          copied=$((copied + 1)); total_bytes=$((total_bytes + size))
          sha="$(hash_file "$destpath")"
          logf "COPIED [$mods] $src -> $destpath"
        else
          outcome="failed-copy"; failed=$((failed + 1))
          err "copy failed (permission denied or unreadable): $src"
        fi
      fi
    fi

    {
      csv_field "$src";      printf ','
      csv_field "$mods";     printf ','
      csv_field "$size";     printf ','
      csv_field "$mtime";    printf ','
      csv_field "$sha";      printf ','
      csv_field "$destpath"; printf ','
      csv_field "$outcome";   printf '\n'
    } >> "$MANIFEST"
  done < "$WORK/hits.dedup.tsv"
}

finalize() {
  local rc="${1:-0}"
  local denials=0
  if [ -f "$ERRLOG" ]; then
    denials="$(grep -c -i -E 'permission denied|not permitted|Operation not permitted' "$ERRLOG" 2>/dev/null | tr -d ' ')"
    [ -n "$denials" ] || denials=0
  fi

  {
    echo "G-Force Extraction — consolidation summary"
    echo "=========================================="
    echo "Machine .............. $MACHINE"
    echo "Run .................. $RUN_STAMP  (v$SCRIPT_VERSION)"
    echo "Archive .............. $ARCHIVE"
    echo "Match mode ........... $PATTERN_LABEL"
    echo "Keywords ............. ${KEYWORDS[*]}"
    echo "Dry run .............. $([ "$DRY_RUN" -eq 1 ] && echo yes || echo no)"
    echo ""
    echo "Files copied ......... $copied"
    echo "Bytes copied ......... $(human_bytes "${total_bytes:-0}")"
    echo "Skipped (too large) .. $skipped_big  (raise with --max-copy-mb)"
    echo "Copy failures ........ $failed"
    echo "Access denials ....... $denials  (see errors_and_denials.txt)"
    echo ""
    echo "Reports .............. $REPORTS_DIR"
    echo "Full log ............. $LOG"
    echo "Manifest ............. $MANIFEST"
    echo ""
    if [ "$denials" -gt 0 ]; then
      echo "ACTION: $denials access denials were recorded. That almost always means"
      echo "Full Disk Access is not granted to the app running this script. Grant it"
      echo "(System Settings > Privacy & Security > Full Disk Access), fully quit that"
      echo "app, and re-run. Re-runs are safe and additive."
    fi
    echo "NOT COVERED (needs a manual export — see the protocol doc):"
    echo "  * Apple Notes bodies (compressed inside NoteStore.sqlite)"
    echo "  * Contacts / Calendar entries"
    echo "  * Photos library assets with no keyword in filename or metadata"
    echo "  * Encrypted disk images and password-protected archives"
    echo "  * Server-side-only mail (IMAP messages never downloaded locally)"
  } > "$SUMMARY"

  [ "$QUIET" -eq 1 ] || cat "$SUMMARY"
  log "Done. Archive: $ARCHIVE"
  cleanup
  exit "$rc"
}

# ------------------------------------------------------------------------------
# 7. MAIN
# ------------------------------------------------------------------------------

log "############################################################"
log "$SCRIPT_NAME v$SCRIPT_VERSION — starting run $RUN_STAMP"
log "Machine: $MACHINE"
log "Archive: $ARCHIVE"
log "Match mode: $PATTERN_LABEL  |  pattern: $PATTERN"
log "Keywords: ${KEYWORDS[*]}"
log "Scan roots: ${SCAN_ROOTS[*]}"
log "############################################################"

module_icloud       # first: materialize cloud files so later modules can see them
module_spotlight
module_names
module_folders
module_content
module_office
module_pdf
module_mail
module_messages
module_browsers

consolidate
finalize 0
