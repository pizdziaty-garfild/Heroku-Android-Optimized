#!/bin/bash
# Patch installer to remove license checks and integrate multi-instance tools
set -euo pipefail
ROOT_DIR="$HOME/Heroku-Android-Optimized"

# 1) Ensure multi-instance helper exists
install -m 0755 android/multi_instance.sh "$ROOT_DIR/android/multi_instance.sh"

# 2) Remove license checks in Python code (no-op if not present)
# Common patterns: LICENSE_KEY, license_key, check_license, validate_license
# This performs surgical neutralization comments for known patterns.
for f in $(grep -RIlE "LICENSE_KEY|license_key|check_license|validate_license" "$ROOT_DIR" || true); do
  echo "Patching license in $f"
  sed -i \
    -e 's/\(check_license\s*(.*)\)/# \1  # disabled on Android/g' \
    -e 's/\(validate_license\s*(.*)\)/# \1  # disabled on Android/g' \
    -e 's/\(LICENSE_KEY\)/DISABLED_LICENSE_KEY/g' \
    -e 's/\(license_key\)/disabled_license_key/g' \
    "$f" || true
done

echo "✅ License checks disabled (if present). Multi-instance tool installed."
