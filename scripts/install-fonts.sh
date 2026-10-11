#!/usr/bin/env bash
# install-fonts.sh — fetch the open-source fonts this setup uses.
#
# Installs:
#   - JetBrainsMono Nerd Font (full set, incl. Mono variants) -> ~/.local/share/fonts/JetBrainsMonoNerd
#   - Inter (static, from the rsms/inter release)             -> ~/.local/share/fonts/Inter
#   - Arial (regular/bold/italic/bold-italic)                 -> ~/.local/share/fonts/MSFonts
#     Redistributable under the Microsoft core fonts EULA; canonical source is
#     sourceforge.net/projects/corefonts, fetched here as raw TTFs from the
#     ImageMagick/msttcorefonts mirror (no cabextract needed).
#
# NOT installed here (proprietary, not redistributable) — copy yourself:
#   - Segoe UI — copy segoeui*.ttf from a Windows install
#     (C:\Windows\Fonts\segoeui*.ttf) into ~/.local/share/fonts/SegoeUI/
#   - Calibri (+Calibri Bold) — from a Microsoft Office install
#     (C:\Windows\Fonts\calibri*.ttf) into ~/.local/share/fonts/calibri/
#
# Idempotent: skips fonts that are already present. No sudo needed.
set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts"
JBM_VERSION="v3.3.0"          # bump as needed; nerd-fonts release tag
INTER_VERSION="v4.1"          # bump as needed; rsms/inter release tag

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# ---- JetBrainsMono Nerd Font -------------------------------------------------
if [ ! -f "$FONT_DIR/JetBrainsMonoNerd/JetBrainsMonoNerdFont-Regular.ttf" ]; then
  log "Fetching JetBrainsMono Nerd Font $JBM_VERSION"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/jbm.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/$JBM_VERSION/JetBrainsMono.zip"
  mkdir -p "$FONT_DIR/JetBrainsMonoNerd"
  python3 - "$tmp" <<'PY'
import pathlib, shutil, sys, zipfile
src, dst = pathlib.Path(sys.argv[1]), pathlib.Path.home()/".local/share/fonts/JetBrainsMonoNerd"
with zipfile.ZipFile(src/"jbm.zip") as z:
    for n in z.namelist():
        if n.lower().endswith((".ttf", ".otf")):
            with z.open(n) as f, open(dst/n.split("/")[-1], "wb") as out:
                shutil.copyfileobj(f, out)
PY
  rm -rf "$tmp"
else
  log "JetBrainsMono Nerd Font already installed"
fi

# ---- Inter (static — variable TTF's family is "Inter Variable" and breaks aliases)
if [ ! -f "$FONT_DIR/Inter/Inter.ttc" ]; then
  log "Fetching Inter $INTER_VERSION"
  tmp="$(mktemp -d)"
  url="https://github.com/rsms/inter/releases/download/$INTER_VERSION/Inter-$INTER_VERSION.zip"
  if ! curl -fsSL -o "$tmp/inter.zip" "$url"; then
    log "Inter $INTER_VERSION not found — falling back to latest release"
    url="$(curl -fsSL https://api.github.com/repos/rsms/inter/releases/latest \
      | grep -o 'https://[^"]*\.zip' | head -1)"
    curl -fsSL -o "$tmp/inter.zip" "$url"
  fi
  mkdir -p "$FONT_DIR/Inter"
  python3 - "$tmp" <<'PY'
import pathlib, shutil, sys, zipfile
src, dst = pathlib.Path(sys.argv[1]), pathlib.Path.home()/".local/share/fonts/Inter"
with zipfile.ZipFile(src/"inter.zip") as z:
    for n in z.namelist():
        if n.endswith("Inter.ttc"):
            with z.open(n) as f, open(dst/"Inter.ttc", "wb") as out:
                shutil.copyfileobj(f, out)
PY
  rm -rf "$tmp"
else
  log "Inter already installed"
fi

# ---- Arial (Microsoft core fonts — redistributable under the MS core fonts EULA;
#      raw TTFs from the ImageMagick/msttcorefonts mirror of sourceforge corefonts)
if [ ! -f "$FONT_DIR/MSFonts/Arial.ttf" ]; then
  log "Fetching Arial (regular + bold + italic + bold-italic)"
  mkdir -p "$FONT_DIR/MSFonts"
  for face in Arial.ttf Arial_Bold.ttf Arial_Italic.ttf Arial_Bold_Italic.ttf; do
    curl -fsSL -o "$FONT_DIR/MSFonts/$face" \
      "https://raw.githubusercontent.com/ImageMagick/msttcorefonts/main/fonts/$face"
  done
else
  log "Arial already installed"
fi

fc-cache -f "$FONT_DIR" >/dev/null 2>&1
log "Done. fc-list | grep -iE 'jetbrains|inter|arial' to verify."
