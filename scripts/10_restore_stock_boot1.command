#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/00_env.zsh"

BOOT1_DIR="$A93S_ROOT/preloader_fastboot_unlock"
STOCK="$BOOT1_DIR/boot1_stock_full.bin"
LOG="$A93S_LOG_DIR/10_restore_stock_boot1_$(date +%Y%m%d_%H%M%S).log"
ATTEMPT="$A93S_LOG_DIR/10_restore_stock_boot1_attempt.tmp"

banner "10_restore_stock_boot1"
echo "Log: $LOG"
echo "目标：恢复完整原厂 UFS boot1/LU1。"

if [[ ! -f "$STOCK" ]]; then
  echo "缺少原厂完整 boot1：$STOCK"
  echo "如果手机还能进 BROM，先运行 07_read_full_boot1.command；否则不要乱写 RAW preloader。"
  read "?按回车关闭窗口。"
  exit 1
fi

size="$(stat -f %z "$STOCK")"
if [[ "$size" != "4194304" ]]; then
  echo "原厂 boot1 大小异常：$size，期望 4194304。"
  read "?按回车关闭窗口。"
  exit 1
fi

wait_hint

while true; do
  echo "--- $(date '+%Y-%m-%d %H:%M:%S') attempt ---" | tee -a "$LOG"
  set +e
  sudo "$A93S_PY" "$A93S_MTK" multi "wf --parttype boot1 $STOCK;reset" 2>&1 | tee "$ATTEMPT"
  code=${pipestatus[1]}
  set -e
  cat "$ATTEMPT" >> "$LOG"

  if [[ "$code" == 0 ]] && grep -Fq "Wrote $STOCK" "$ATTEMPT"; then
    shasum -a 256 "$STOCK" | tee -a "$LOG"
    echo "RESTORE_STOCK_BOOT1_OK" | tee -a "$LOG"
    break
  fi

  echo "未成功，3 秒后重试。拔线，等 Waiting，再三键插线。" | tee -a "$LOG"
  sleep 3
done

echo
echo "下一步：拔线，长按电源 20–30 秒，再单按电源。"
read "?按回车关闭窗口。"
