#!/usr/bin/env bash
# setup-firewall.sh — host firewall baseline (ufw) for laptop use.
# Idempotent: safe to re-run on any boot, after updates, or on a fresh install.
#
# Why this exists — Ubuntu desktop ships with ufw installed but INACTIVE, and
# this box listens on all interfaces for several LAN services (observed
# 2026-10-12: 0.0.0.0:80 lighttpd, 0.0.0.0:41603 rquickshare, *:1716
# kdeconnectd). With no filter, any device on the same LAN / public WiFi can
# reach them. Baseline is deny-incoming / allow-outgoing; localhost and
# established outbound keep working, unsolicited inbound is dropped.
#
# What it does:
#   1. installs ufw (apt) if missing
#   2. sets defaults: deny incoming, allow outgoing
#   3. allows 1716/tcp + 1716/udp (KDE Connect phone link — config versioned
#      in home-kde/, pairing state deliberately NOT versioned)
#   4. stops + disables lighttpd if present (laptop has no business serving
#      :80; docroot was /var/www/html)
#   5. enables ufw (persists across reboots) + verifies
#
# NOT opened: rquickshare 41603/tcp stays blocked by the default-deny unless
# you need LAN file share — then run once:
#   sudo ufw allow 41603/tcp
#
# Needs root: re-execs via pkexec (GUI polkit prompt) or sudo on headless.
set -euo pipefail

# ---- re-exec as root (pkexec preferred, sudo fallback) ----------------------
if [ "$(id -u)" -ne 0 ]; then
  if command -v pkexec >/dev/null 2>&1; then
    exec pkexec "$0" "$@"
  else
    exec sudo "$0" "$@"
  fi
fi

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# ---- 1. ufw present ----------------------------------------------------------
if ! command -v ufw >/dev/null 2>&1; then
  log "ufw missing — installing"
  apt-get install -y ufw
else
  log "ufw present"
fi

# ---- 2. defaults --------------------------------------------------------------
log "Setting defaults (deny incoming, allow outgoing)"
ufw default deny incoming
ufw default allow outgoing

# ---- 3. KDE Connect ------------------------------------------------------------
log "Allowing KDE Connect (1716/tcp + 1716/udp)"
ufw allow 1716/tcp
ufw allow 1716/udp

# ---- 4. lighttpd: no :80 on a laptop --------------------------------------------
if systemctl list-unit-files lighttpd.service >/dev/null 2>&1; then
  log "Disabling lighttpd (was listening on 0.0.0.0:80)"
  systemctl disable --now lighttpd 2>/dev/null || true
else
  log "lighttpd not installed — nothing to disable"
fi

# ---- 5. enable + verify ---------------------------------------------------------
log "Enabling ufw"
ufw --force enable

log "Verifying"
ufw status verbose
echo "  1716 open = $(ufw status | grep -c 1716) rule lines (expect >= 2)"
echo "  rquickshare 41603 stays blocked unless you run: sudo ufw allow 41603/tcp"
