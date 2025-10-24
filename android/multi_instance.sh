#!/bin/bash
# Multi-instance launcher for Android (Termux)
# Usage examples:
#  ./multi_instance.sh create 3              # create 3 instances
#  ./multi_instance.sh start all            # start all instances
#  ./multi_instance.sh start 1 3            # start instances 1 and 3
#  ./multi_instance.sh stop all             # stop all
#  ./multi_instance.sh status               # show status
#  ./multi_instance.sh remove 2             # remove instance 2 (keeps sessions unless --purge)

set -euo pipefail
BASE_DIR="$HOME/Heroku-Android-Optimized/instances"
UPSTREAM_DIR="$HOME/Heroku-Android-Optimized"
PYTHON_BIN="python3"

mkdir -p "$BASE_DIR"

ensure_instance_layout(){
  local id="$1"
  local dir="$BASE_DIR/userbot_$id"
  mkdir -p "$dir"
  if [ ! -d "$dir/heroku" ]; then
    rsync -a --exclude 'instances' --exclude '.git' "$UPSTREAM_DIR/" "$dir/"
  fi
  echo "$dir"
}

create_instances(){
  local n="$1"
  for i in $(seq 1 "$n"); do
    local dir
    dir=$(ensure_instance_layout "$i")
    echo "Created instance $i at $dir"
  done
}

start_instance(){
  local id="$1"; shift || true
  local dir
  dir=$(ensure_instance_layout "$id")
  cd "$dir"
  if command -v tmux >/dev/null 2>&1; then
    tmux new-session -d -s "ub$id" "$PYTHON_BIN -m hikka --android-mode --session userbot_$id.session"
    echo "Started instance $id in tmux session ub$id"
  else
    nohup $PYTHON_BIN -m hikka --android-mode --session userbot_$id.session >/dev/null 2>&1 &
    echo $! > "$dir/.pid"
    echo "Started instance $id as background process (PID $(cat "$dir/.pid"))"
  fi
}

stop_instance(){
  local id="$1"
  if command -v tmux >/dev/null 2>&1; then
    tmux kill-session -t "ub$id" 2>/dev/null || true
  fi
  local pidfile="$BASE_DIR/userbot_$id/.pid"
  if [ -f "$pidfile" ]; then
    kill "$(cat "$pidfile")" 2>/dev/null || true
    rm -f "$pidfile"
  fi
  echo "Stopped instance $id"
}

status_instances(){
  if command -v tmux >/dev/null 2>&1; then
    tmux ls 2>/dev/null | grep -E '^ub[0-9]+' || echo "No tmux instances"
  fi
  for d in "$BASE_DIR"/userbot_*; do
    [ -d "$d" ] || continue
    id="${d##*/userbot_}"
    if [ -f "$d/.pid" ] && ps -p "$(cat "$d/.pid")" >/dev/null 2>&1; then
      echo "Instance $id: running (PID $(cat "$d/.pid"))"
    else
      echo "Instance $id: stopped"
    fi
  done
}

remove_instance(){
  local id="$1"; shift || true
  local purge="false"
  if [ "${1:-}" = "--purge" ]; then purge="true"; fi
  stop_instance "$id" || true
  local dir="$BASE_DIR/userbot_$id"
  if [ "$purge" = "true" ]; then
    rm -rf "$dir"
    echo "Removed instance $id (purged)"
  else
    rm -rf "$dir/heroku" "$dir/web-resources" "$dir/*.py" 2>/dev/null || true
    echo "Removed code for instance $id (sessions retained)"
  fi
}

case "${1:-}" in
  create)
    create_instances "${2:-1}"
    ;;
  start)
    shift
    if [ "${1:-}" = "all" ]; then
      for d in "$BASE_DIR"/userbot_*; do [ -d "$d" ] || continue; id="${d##*/userbot_}"; start_instance "$id"; done
    else
      for id in "$@"; do start_instance "$id"; done
    fi
    ;;
  stop)
    shift
    if [ "${1:-}" = "all" ]; then
      for d in "$BASE_DIR"/userbot_*; do [ -d "$d" ] || continue; id="${d##*/userbot_}"; stop_instance "$id"; done
    else
      for id in "$@"; do stop_instance "$id"; done
    fi
    ;;
  status)
    status_instances
    ;;
  remove)
    remove_instance "${2:-1}" "${3:-}"
    ;;
  *)
    echo "Usage: $0 {create N|start [all|ids]|stop [all|ids]|status|remove ID [--purge]}";
    ;;
esac
