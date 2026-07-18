#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/00_env.zsh"

BOOT1_DIR="$A93S_ROOT/preloader_fastboot_unlock"
CAND="$BOOT1_DIR/boot1_fastboot_unlock_candidate.bin"
STOCK="$BOOT1_DIR/boot1_stock_full.bin"
STAMP="$(date +%Y%m%d_%H%M%S)"
CURRENT="$BOOT1_DIR/boot1_before_fastboot_patch_$STAMP.bin"
LOG="$A93S_LOG_DIR/09_flash_fastboot_preloader_$STAMP.log"
ATTEMPT="$A93S_LOG_DIR/09_flash_fastboot_preloader_attempt.tmp"

banner "09_flash_fastboot_preloader"
echo "Log: $LOG"
echo "目标：写入 fastboot-unlock 候选 preloader 到 UFS boot1/LU1。"
echo "风险：这是 preloader，风险高于 LK；写错可能黑砖。"

for item in "$CAND" "$STOCK"; do
  if [[ ! -f "$item" ]]; then
    echo "缺文件：$item"
    read "?按回车关闭窗口。"
    exit 1
  fi
  size="$(stat -f %z "$item")"
  if [[ "$size" != "4194304" ]]; then
    echo "文件大小异常：$item size=$size，期望 4194304。"
    read "?按回车关闭窗口。"
    exit 1
  fi
done

if cmp -s "$CAND" "$STOCK"; then
  echo "候选文件和原厂 boot1 完全相同，停止。"
  read "?按回车关闭窗口。"
  exit 1
fi

echo
echo "继续前必须手动输入：I_UNDERSTAND_PRELOADER_RISK"
read "?确认码：" confirm
if [[ "$confirm" != "I_UNDERSTAND_PRELOADER_RISK" ]]; then
  echo "确认码不对，停止。"
  read "?按回车关闭窗口。"
  exit 1
fi

wait_hint

while true; do
  echo "--- $(date '+%Y-%m-%d %H:%M:%S') attempt ---" | tee -a "$LOG"
  set +e
  sudo "$A93S_PY" "$A93S_MTK" multi "rf --parttype boot1 $CURRENT --length 0x400000;wf --parttype boot1 $CAND;reset" 2>&1 | tee "$ATTEMPT"
  code=${pipestatus[1]}
  set -e
  cat "$ATTEMPT" >> "$LOG"

  if [[ "$code" == 0 ]] && grep -Fq "Wrote $CAND" "$ATTEMPT"; then
    if [[ -f "$CURRENT" && "$(stat -f %z "$CURRENT")" == "4194304" ]]; then
      shasum -a 256 "$CURRENT" "$CAND" "$STOCK" | tee -a "$LOG"
      echo "FLASH_FASTBOOT_PRELOADER_OK" | tee -a "$LOG"
      break
    fi
    echo "写入前备份大小异常，停止重试，请先检查：$CURRENT" | tee -a "$LOG"
    exit 1
  fi

  echo "未成功，3 秒后重试。拔线，等 Waiting，再三键插线。" | tee -a "$LOG"
  sleep 3
done

echo
echo "下一步：拔线，长按电源 20–30 秒。能进系统就运行 11_fastboot_unlock_official.command。"
echo "如果不开机/异常，运行 10_restore_stock_boot1.command 恢复完整 boot1。"
read "?按回车关闭窗口。"
