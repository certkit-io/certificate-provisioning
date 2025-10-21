#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Expecting certkit.conf file to exist within the same directory as this script.
# Expected vars:
# CERTKIT_CERTIFICATE_DOMAIN
# CERTKIT_S3_ACCESS_KEY
# CERTKIT_S3_SECRET_KEY
# CERTKIT_S3_BUCKET
# DESTINATION_PEM_FILE
# DESTINATION_KEY_FILE
# UPDATE_CERTIFICATE_CMD

# To add to cron, and have this script sync daily at 2am:
# (crontab -l 2>/dev/null; echo "0 2 * * * /path/to/certkit-sync.sh") | crontab -

# Check whether we're running in interactive mode or unattended.
if [ -t 1 ] ; then 
    INTERACTIVE_MODE=true
else
    INTERACTIVE_MODE=false
fi

# Check for command line override to run immediately.
if [[ "${1-}" = "--start-now" ]]; then
    START_NOW=true
else
    START_NOW=false
fi

# --- Settings (all paths relative to the script directory) ---
MC_DOWNLOAD_URL="https://dl.min.io/client/mc/release/linux-amd64/mc"

# Locate the directory this script lives in (not the caller's cwd)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"


LOG_FILE="${SCRIPT_DIR}/certkit.log"
CONFIG_FILE="${SCRIPT_DIR}/certkit.conf"   # always certkit.conf per your request

# Truncate log before starting, so it never grows too large (2000 lines for now)
if [[ -f "$LOG_FILE" ]]; then
  TMP_LOG="${LOG_FILE}.tmp"
  tail -n 2000 "$LOG_FILE" > "$TMP_LOG"
  mv "$TMP_LOG" "$LOG_FILE"
fi

# Log to a local file in the script folder
exec > >(tee -a "$LOG_FILE") 2>&1

if $INTERACTIVE_MODE || $START_NOW; then
    echo "== $(date -Is) | Starting CertKit synchronization"
else
    SLEEP_SECS=$(( 30 + RANDOM % (300 - 30 + 1) ))
    echo "== $(date -Is) | Starting CertKit synchronization in $SLEEP_SECS seconds."
    sleep "$SLEEP_SECS"
fi

echo "Script dir: $SCRIPT_DIR"
echo "Config:     $CONFIG_FILE"
[[ -f "$CONFIG_FILE" ]] || { echo "Config not found: $CONFIG_FILE"; exit 1; }
# shellcheck source=/dev/null
source "$CONFIG_FILE"

# Normalize directory and file names based on wildcard or not
if [[ "$CERTKIT_CERTIFICATE_DOMAIN" == \*.* ]]; then
  # Strip leading "*." for folder name
  S3_FOLDER_NAME="${CERTKIT_CERTIFICATE_DOMAIN#*.}"
  CERT_BASENAME="wildcard.${CERTKIT_CERTIFICATE_DOMAIN#*.}"
else
  S3_FOLDER_NAME="${CERTKIT_CERTIFICATE_DOMAIN}"
  CERT_BASENAME="${CERTKIT_CERTIFICATE_DOMAIN}"
fi

CERT_DIR="${SCRIPT_DIR}/certs/${CERT_BASENAME}"
CERTKIT_PEM_FILE="${CERT_BASENAME}.pem"
CERTKIT_KEY_FILE="${CERT_BASENAME}.key"

mkdir -p "$CERT_DIR"

# Ensure MinIO client (mc) is present locally next to the script
MC_BIN="${SCRIPT_DIR}/mc"
if [[ -x "$MC_BIN" ]]; then
  echo "mc found at $MC_BIN"
else
  echo "mc not found; downloading..."
  curl -fsSL -o "$MC_BIN" "$MC_DOWNLOAD_URL"
  chmod +x "$MC_BIN"
  echo "mc downloaded."
fi

# Record the time before sync so we can detect 'new' files
SYNC_TIME="$(date +%s)"

# Build storage URL and sync
CERTKIT_STORAGE_URL="https://${CERTKIT_S3_ACCESS_KEY}:${CERTKIT_S3_SECRET_KEY}@storage.certkit.io"

export MC_HOST_certkit="$CERTKIT_STORAGE_URL"
echo "Mirroring from certkit/${CERTKIT_S3_BUCKET}/${S3_FOLDER_NAME}/ to $CERT_DIR"
"$MC_BIN" mirror --overwrite "certkit/${CERTKIT_S3_BUCKET}/${S3_FOLDER_NAME}/" "$CERT_DIR"

# Determine if anything updated since SYNC_TIME
UPDATED_FILES="$(find "$CERT_DIR" -type f -newermt "@$SYNC_TIME" -printf "%P\n" || true)"
if [[ -n "${UPDATED_FILES:-}" ]]; then
  echo "Detected updated files after sync:"
  printf '  - %s\n' $UPDATED_FILES
else
  echo "No files updated after sync timestamp."
fi

# Helper for safe compare; returns 0 (true) if different, 1 if same or one missing
files_differ() {
  local src="$1" dst="$2"
  if [[ ! -f "$src" || ! -f "$dst" ]]; then
    return 1  # treat missing as "can't assert difference" (handled elsewhere)
  fi
  if cmp -s -- "$src" "$dst"; then
    return 1  # same
  fi
  return 0    # differ
}

SRC_PEM="${CERT_DIR}/${CERTKIT_PEM_FILE}"
SRC_KEY="${CERT_DIR}/${CERTKIT_KEY_FILE}"

NEED_UPDATE=false
REASONS=()

# If destination files missing, we must update
if [[ ! -f "${DESTINATION_PEM_FILE}" || ! -f "${DESTINATION_KEY_FILE}" ]]; then
  NEED_UPDATE=true
  REASONS+=("destination file(s) missing")
fi

# If files were updated during this sync, we should update
if [[ -n "${UPDATED_FILES:-}" ]]; then
  NEED_UPDATE=true
  REASONS+=("synced files updated")
fi

# Even if nothing is 'new', apply if content differs
if files_differ "$SRC_PEM" "$DESTINATION_PEM_FILE"; then
  NEED_UPDATE=true
  REASONS+=("PEM differs from destination")
fi
if files_differ "$SRC_KEY" "$DESTINATION_KEY_FILE"; then
  NEED_UPDATE=true
  REASONS+=("KEY differs from destination")
fi

if $NEED_UPDATE; then
  echo "Update required due to: ${REASONS[*]}"
  mkdir -p "$(dirname -- "$DESTINATION_PEM_FILE")"
  mkdir -p "$(dirname -- "$DESTINATION_KEY_FILE")"

  # Copy into place atomically where possible
  echo "Copying certificate files..."
  cp -f -- "$SRC_PEM" "$DESTINATION_PEM_FILE"
  cp -f -- "$SRC_KEY" "$DESTINATION_KEY_FILE"

  # Run post-update hook if set
  if [[ -n "${UPDATE_CERTIFICATE_CMD:-}" ]]; then
    echo "Running UPDATE_CERTIFICATE_CMD..."
    bash -c "$UPDATE_CERTIFICATE_CMD"
  else
    echo "No UPDATE_CERTIFICATE_CMD set; skipping."
  fi
else
  echo "Certificates are up to date; no action needed."
fi

sleep 0.1
echo "== $(date -Is) | Done"