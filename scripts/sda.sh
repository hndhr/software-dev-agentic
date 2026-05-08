#!/usr/bin/env bash
# sda.sh — CLI entry point for software-dev-agentic setup and sync.
#
# Usage:
#   scripts/sda.sh                        # interactive menu
#   scripts/sda.sh setup --platform=ios   # first-time wiring
#   scripts/sda.sh sync                   # pull latest from main

set -euo pipefail

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

# ── Helpers ───────────────────────────────────────────────────────────────────

bold()  { printf '\033[1m%s\033[0m' "$*"; }
dim()   { printf '\033[2m%s\033[0m' "$*"; }

print_header() {
  echo ""
  echo "$(bold 'software-dev-agentic')"
  echo "$(dim '─────────────────────')"
  echo ""
}

ask_platform() {
  echo "  Platform:"
  echo "    1) ios"
  echo "    2) web"
  echo "    3) flutter"
  echo "    4) other"
  echo ""
  printf "  Choice: "
  read -r choice
  case "$choice" in
    1) PLATFORM="ios" ;;
    2) PLATFORM="web" ;;
    3) PLATFORM="flutter" ;;
    4)
      printf "  Platform name: "
      read -r PLATFORM
      ;;
    *) PLATFORM="$choice" ;;
  esac
  echo ""
}

# ── Parse command + passthrough args ─────────────────────────────────────────

COMMAND=""
PASSTHROUGH=()

for arg in "$@"; do
  case "$arg" in
    setup|sync) COMMAND="$arg" ;;
    *)          PASSTHROUGH+=("$arg") ;;
  esac
done

# ── Interactive menu (no command given) ───────────────────────────────────────

if [ -z "$COMMAND" ]; then
  print_header
  echo "  What do you want to do?"
  echo ""
  echo "    1) $(bold Setup)  — first-time wiring into a project"
  echo "    2) $(bold Sync)   — pull latest from main"
  echo ""
  printf "  Choice [1/2]: "
  read -r choice
  echo ""
  case "$choice" in
    1|setup) COMMAND="setup" ;;
    2|sync)  COMMAND="sync"  ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
fi

# ── Detect platform from passthrough args ────────────────────────────────────

PLATFORM=""
for arg in "${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}"; do
  case "$arg" in
    --platform=*) PLATFORM="${arg#--platform=}" ;;
  esac
done

# ── Run ───────────────────────────────────────────────────────────────────────

case "$COMMAND" in
  setup)
    if [ -z "$PLATFORM" ]; then
      ask_platform
      PASSTHROUGH+=("--platform=$PLATFORM")
    fi
    exec "$SCRIPTS/setup-symlinks.sh" "${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}"
    ;;
  sync)
    exec "$SCRIPTS/sync.sh" "${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}"
    ;;
  *)
    echo "Unknown command: $COMMAND"
    echo "Usage: $0 [setup|sync] [--platform=<platform>]"
    exit 1
    ;;
esac
