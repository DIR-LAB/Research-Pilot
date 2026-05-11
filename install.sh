#!/usr/bin/env bash
# Research Copilot installer (macOS + Linux)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/DIR-LAB/Research-Pilot/main/install.sh | bash
#
# Detects OS + architecture, downloads the latest signed-or-not release asset
# from GitHub, installs it locally, and (on macOS) clears Gatekeeper quarantine.

set -euo pipefail

REPO="DIR-LAB/Research-Pilot"
APP_NAME="Research Copilot"
API_LATEST="https://api.github.com/repos/${REPO}/releases/latest"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
info()  { printf '  %s\n' "$*"; }
warn()  { printf '\033[33m  ! %s\033[0m\n' "$*"; }
err()   { printf '\033[31m  ✗ %s\033[0m\n' "$*" >&2; }
ok()    { printf '\033[32m  ✓ %s\033[0m\n' "$*"; }

require() {
  command -v "$1" >/dev/null 2>&1 || { err "missing required command: $1"; exit 1; }
}

require curl
require uname

OS="$(uname -s)"
ARCH="$(uname -m)"

bold "Research Copilot installer"
info "OS:   ${OS}"
info "Arch: ${ARCH}"

# ---------- Resolve asset URL from GitHub Releases ----------
fetch_release_json() {
  if command -v jq >/dev/null 2>&1; then
    curl -fsSL "$API_LATEST"
  else
    curl -fsSL "$API_LATEST"
  fi
}

pick_asset_url() {
  # $1 = regex matching the desired asset name
  # $2 = optional regex to exclude (skip assets whose name matches this)
  local pattern="$1"
  local exclude="${2:-}"
  local json
  json="$(fetch_release_json)"
  if command -v jq >/dev/null 2>&1; then
    echo "$json" | jq -r --arg p "$pattern" --arg x "$exclude" '
      .assets[]
      | select(.name | test($p))
      | select($x == "" or (.name | test($x) | not))
      | .browser_download_url' | head -n 1
  else
    local urls
    urls="$(echo "$json" \
      | grep -Eo '"browser_download_url"\s*:\s*"[^"]+"' \
      | sed -E 's/.*"([^"]+)"$/\1/' \
      | grep -E "$pattern")"
    if [ -n "$exclude" ]; then
      urls="$(echo "$urls" | grep -vE "$exclude")"
    fi
    echo "$urls" | head -n 1
  fi
}

EXCLUDE=''
case "$OS" in
  Darwin)
    case "$ARCH" in
      arm64)        PATTERN='-arm64\.dmg$' ;;
      x86_64|amd64) PATTERN='\.dmg$'; EXCLUDE='arm64' ;;
      *)            err "unsupported macOS arch: $ARCH"; exit 1 ;;
    esac
    ;;
  Linux)
    case "$ARCH" in
      x86_64|amd64) PATTERN='\.AppImage$' ;;
      *)            err "unsupported Linux arch: $ARCH (only x86_64 builds are published)"; exit 1 ;;
    esac
    ;;
  *)
    err "unsupported OS: $OS"
    err "Windows users: see https://github.com/${REPO}#installation for the PowerShell installer."
    exit 1
    ;;
esac

bold "Resolving latest release asset…"
URL="$(pick_asset_url "$PATTERN" "$EXCLUDE")"
if [ -z "${URL:-}" ]; then
  err "no matching asset found for pattern: $PATTERN"
  err "check https://github.com/${REPO}/releases/latest"
  exit 1
fi
ok "found: $URL"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FILE="$TMP/$(basename "$URL")"

bold "Downloading…"
curl -fL --progress-bar -o "$FILE" "$URL"
ok "saved to $FILE"

# ---------- Install ----------
case "$OS" in
  Darwin)
    bold "Mounting DMG…"
    MNT="$(hdiutil attach -nobrowse -readonly "$FILE" | awk '/\/Volumes\// { for (i=3;i<=NF;i++) printf "%s%s",$i,(i<NF?OFS:""); print "" }' | tail -n 1)"
    if [ -z "$MNT" ] || [ ! -d "$MNT" ]; then
      err "failed to mount DMG"; exit 1
    fi
    info "mounted at: $MNT"

    SRC="$MNT/${APP_NAME}.app"
    if [ ! -d "$SRC" ]; then
      err "expected ${APP_NAME}.app inside DMG, not found"
      hdiutil detach "$MNT" -quiet || true
      exit 1
    fi

    DEST="/Applications/${APP_NAME}.app"
    if [ -d "$DEST" ]; then
      warn "removing existing $DEST"
      rm -rf "$DEST"
    fi

    bold "Copying to /Applications…"
    cp -R "$SRC" "/Applications/"
    ok "installed to $DEST"

    hdiutil detach "$MNT" -quiet || true

    bold "Clearing Gatekeeper quarantine (unsigned build workaround)…"
    if xattr -dr com.apple.quarantine "$DEST" 2>/dev/null; then
      ok "quarantine attribute cleared"
    else
      warn "could not clear quarantine — first launch may show a Gatekeeper warning"
      warn "you can run manually: xattr -dr com.apple.quarantine \"$DEST\""
    fi

    bold "Done."
    info "Launch:  open \"$DEST\""
    info "Or find Research Copilot in /Applications."
    ;;

  Linux)
    if ! command -v fusermount >/dev/null 2>&1 && ! command -v fusermount3 >/dev/null 2>&1; then
      warn "FUSE not detected. AppImage may fail to launch."
      warn "Install with: sudo apt install libfuse2   (Debian/Ubuntu)"
      warn "Or run with --appimage-extract-and-run if FUSE is unavailable."
    fi

    INSTALL_DIR="${HOME}/.local/bin"
    APP_DIR="${HOME}/.local/share/research-copilot"
    DESKTOP_DIR="${HOME}/.local/share/applications"
    ICON_DIR="${HOME}/.local/share/icons/hicolor/512x512/apps"
    mkdir -p "$INSTALL_DIR" "$APP_DIR" "$DESKTOP_DIR" "$ICON_DIR"

    DEST="${APP_DIR}/research-copilot.AppImage"
    cp "$FILE" "$DEST"
    chmod +x "$DEST"
    ok "installed AppImage to $DEST"

    LINK="${INSTALL_DIR}/research-copilot"
    ln -sf "$DEST" "$LINK"
    ok "symlinked to $LINK"

    # Try to extract icon for menu integration (best-effort).
    EXTRACT_DIR="${TMP}/squashfs-root"
    if (cd "$TMP" && "$DEST" --appimage-extract >/dev/null 2>&1); then
      ICON_SRC="$(find "$EXTRACT_DIR" -maxdepth 2 -name '*.png' | head -n 1 || true)"
      if [ -n "$ICON_SRC" ]; then
        cp "$ICON_SRC" "${ICON_DIR}/research-copilot.png" || true
      fi
    fi

    cat > "${DESKTOP_DIR}/research-copilot.desktop" <<EOF
[Desktop Entry]
Name=Research Copilot
Comment=AI-powered research assistant
Exec=${DEST} %U
Icon=research-copilot
Type=Application
Categories=Science;Education;Office;
Terminal=false
EOF
    ok "wrote desktop entry: ${DESKTOP_DIR}/research-copilot.desktop"

    if command -v update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
    fi

    bold "Done."
    info "Launch:  research-copilot   (if ${INSTALL_DIR} is on your PATH)"
    info "Or find Research Copilot in your application menu."
    case ":${PATH}:" in
      *":${INSTALL_DIR}:"*) ;;
      *) warn "${INSTALL_DIR} is not on your PATH — add it to your shell rc to launch by name." ;;
    esac
    ;;
esac
