#!/bin/bash
# Wrapper to fetch and run the Termux installer directly from repo
set -euo pipefail
RAW="https://raw.githubusercontent.com/pizdziaty-garfild/Heroku-Android-Optimized/main/android/termux_installer.sh"
curl -fsSL "$RAW" | bash
