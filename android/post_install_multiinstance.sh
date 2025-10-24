#!/bin/bash
# Integrate multi-instance workflow into Termux installer
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ROOT_DIR="$HOME/Heroku-Android-Optimized"

# Ensure multi-instance tool exists in target
install -m 0755 "$SCRIPT_DIR/multi_instance.sh" "$ROOT_DIR/android/multi_instance.sh" || true

# Install tmux if available choice
if ! command -v tmux >/dev/null 2>&1; then
  echo "[INFO] tmux not found. Installing for better multi-instance management..."
  pkg install -y tmux || true
fi

echo "[OK] Multi-instance support installed. Usage examples:"
echo "  bash $ROOT_DIR/android/multi_instance.sh create 3"
echo "  bash $ROOT_DIR/android/multi_instance.sh start all"
echo "  bash $ROOT_DIR/android/multi_instance.sh status"
