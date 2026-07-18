#!/bin/zsh

set -euo pipefail

export A93S_ROOT="${SCRIPT_DIR:h}"
export A93S_MTK_DIR="$A93S_ROOT/tools/mtkclient"
export A93S_PY="$A93S_MTK_DIR/.venv/bin/python"
export A93S_MTK="$A93S_MTK_DIR/mtk.py"
export A93S_LK_PACK="$A93S_ROOT/stock_images"
export A93S_LOG_DIR="$A93S_ROOT/logs_runtime"

mkdir -p "$A93S_LOG_DIR"

require_files() {
  local missing=0
  for item in \
    "$A93S_PY" \
    "$A93S_MTK" \
    "$A93S_ROOT/stock_images/lk_stock.img" \
    "$A93S_ROOT/stock_images/lk2_stock.img"
  do
    if [[ ! -e "$item" ]]; then
      echo "缺文件: $item"
      missing=1
    fi
  done
  if [[ "$missing" != 0 ]]; then
    echo "文件不齐，停止。"
    exit 1
  fi
}

banner() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

wait_hint() {
  echo
  echo "操作手机："
  echo "1. 先拔 USB。"
  echo "2. 手机黑屏/关机状态。"
  echo "3. 看到 Waiting 后，按住 音量上 + 音量下 + 电源，同时插 USB。"
  echo "4. mtkclient 一识别到 MT6833 后就松手。"
  echo
}

run_loop() {
  local title="$1"
  local command="$2"
  local ok_mark="$3"
  local expect_text="${4:-Reset command was sent}"
  local log="$A93S_LOG_DIR/${title}_$(date +%Y%m%d_%H%M%S).log"
  local attempt_log="$A93S_LOG_DIR/${title}_attempt.tmp"

  banner "$title"
  echo "Log: $log"
  wait_hint

  while true; do
    echo "--- $(date '+%Y-%m-%d %H:%M:%S') attempt ---"
    set +e
    sudo "$A93S_PY" "$A93S_MTK" multi "$command" 2>&1 | tee "$attempt_log"
    local code=$?
    set -e
    cat "$attempt_log" >> "$log"
    echo "attempt exit code: $code"
    if [[ "$code" == 0 ]] && grep -Fq "$expect_text" "$attempt_log" && ! grep -Fq "Please disconnect" "$attempt_log"; then
      echo "$ok_mark"
      echo "$ok_mark" >> "$log"
      rm -f "$attempt_log"
      break
    fi
    echo "未成功，3 秒后重试。拔线，等 Waiting，再三键插线。"
    sleep 3
  done 2>&1 | tee -a "$log"

  echo
  echo "完成。日志：$log"
}
