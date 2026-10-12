#!/usr/bin/env bash
# setup-pro.sh — attach this machine to Ubuntu Pro (free personal) so
# Universe/Multiverse security updates actually arrive.
# Idempotent: safe to re-run; skips attach when already attached.
#
# Why this exists — on Ubuntu 24.04, Main/Restricted get 5 years of free
# security, but Universe/Multiverse fixes (ffmpeg, qt5, flatpak, 7zip,
# aiohttp, ...) ship via esm-apps, which needs a Pro attach. Observed
# 2026-10-12: 50 security updates withheld until attach; 0 pending after.
#
# Usage:
#   ./setup-pro.sh [TOKEN]     # token from ubuntu.com/pro/dashboard
#   ./setup-pro.sh             # prompts (input hidden) when no arg given
#
# NEVER commit your token — this repo is public. The token is per-account;
# each fresh machine attaches with its own `pro attach` run.
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

TOKEN="${1:-}"
[ -n "$TOKEN" ] || { printf 'Ubuntu Pro token (ubuntu.com/pro/dashboard): '; read -rs TOKEN; echo; }
[ -n "$TOKEN" ] || { echo "ERROR: no token given" >&2; exit 1; }

if pro status 2>/dev/null | grep -q 'attached to an Ubuntu Pro'; then
  log "Already attached — ensuring esm-apps + esm-infra"
else
  log "Attaching to Ubuntu Pro"
  sudo pro attach "$TOKEN"
fi

log "Enabling esm-apps + esm-infra"
sudo pro enable esm-apps esm-infra || true

log "Upgrading (picks up esm-apps/esm-infra fixes)"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

log "Verifying"
apt list --upgradable 2>/dev/null
pro security-status 2>&1 | head -20
