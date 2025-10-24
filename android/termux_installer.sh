#!/bin/bash
# Heroku-Android-Optimized Installer for Termux (with multi-instance and license patch integration)
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log(){ echo -e "${BLUE}[INFO]${NC} $*"; }; ok(){ echo -e "${GREEN}[OK]${NC} $*"; }; warn(){ echo -e "${YELLOW}[WARN]${NC} $*"; }; err(){ echo -e "${RED}[ERROR]${NC} $*"; }

log "Detecting Android device..."
DEVICE_MODEL=$(getprop ro.product.model || true)
DEVICE_CODE=$(getprop ro.product.device || true)
ANDROID_VERSION=$(getprop ro.build.version.release || true)
log "Device: ${DEVICE_MODEL:-Unknown} (${DEVICE_CODE:-unknown}), Android ${ANDROID_VERSION:-unknown}"

if [ ! -d "/data/data/com.termux" ]; then err "Termux not detected. Install from F-Droid"; exit 1; fi
ok "Termux detected"

pkg update -y && pkg upgrade -y
pkg install -y python git curl wget jq clang make cmake pkg-config libffi openssl tmux || true
if ! command -v rustc >/dev/null 2>&1; then pkg install -y rust || true; fi
termux-setup-storage || true
python -m pip install --upgrade pip setuptools wheel

REPO_URL="https://github.com/pizdziaty-garfild/Heroku-Android-Optimized.git"
REPO_DIR="$HOME/Heroku-Android-Optimized"
if [ ! -d "$REPO_DIR/.git" ]; then git clone "$REPO_URL" "$REPO_DIR"; else git -C "$REPO_DIR" pull --ff-only || true; fi

cd "$REPO_DIR"

if [ -f "requirements_android.txt" ]; then python -m pip install -r requirements_android.txt; else warn "Falling back to requirements.txt"; python -m pip install -r requirements.txt; fi

# Apply Android patches: disable license checks if present, install multi-instance tool
bash android/apply_android_patches.sh || true
bash android/post_install_multiinstance.sh || true

cat > start_userbot.sh << 'EOF'
#!/bin/bash
set -euo pipefail
export ANDROID_OPTIMIZED=true
export TERMUX_ENVIRONMENT=true
BATTERY_JSON=$(termux-battery-status 2>/dev/null || echo '{}')
BATTERY_PCT=$(echo "$BATTERY_JSON" | jq -r '.percentage // empty' 2>/dev/null || echo "")
if [ -n "$BATTERY_PCT" ]; then echo "🔋 Battery: ${BATTERY_PCT}%"; if [ "$BATTERY_PCT" -lt 20 ]; then echo "⚠️ Low battery — consider charging"; fi; fi
exec python3 -m hikka --android-mode
EOF
chmod +x start_userbot.sh

ok "Installation complete"
echo "Next steps:"
echo "  1) Get API_ID/API_HASH from my.telegram.org"
echo "  2) Run: ./start_userbot.sh"
echo "  3) Multi-instance: bash android/multi_instance.sh create 3 && bash android/multi_instance.sh start all"
