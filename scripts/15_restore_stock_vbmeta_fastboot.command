#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/00_env.zsh"

FIX_ROOT="$A93S_ROOT/vbmeta_dmverity_fix"
VBMETA="$FIX_ROOT/vbmeta_stock.img"
LOG="$A93S_LOG_DIR/15_restore_stock_vbmeta_fastboot_$(date +%Y%m%d_%H%M%S).log"

banner "15_restore_stock_vbmeta_fastboot"
echo "Log: $LOG"
echo "目标：恢复原厂顶层 vbmeta。"

if [[ ! -s "$VBMETA" ]]; then
  echo "缺少 vbmeta 备份：$VBMETA"
  read "?按回车关闭窗口。"
  exit 1
fi

echo "继续前输入：RESTORE_STOCK_VBMETA"
read "?确认码：" confirm
if [[ "$confirm" != "RESTORE_STOCK_VBMETA" ]]; then
  echo "确认码不对，停止。"
  read "?按回车关闭窗口。"
  exit 1
fi

{
  adb wait-for-device
  adb reboot bootloader || true
  sleep 5
  for i in {1..90}; do
    if fastboot devices | grep -q .; then
      break
    fi
    sleep 1
    printf "."
  done
  echo
  fastboot devices
  fastboot flash vbmeta "$VBMETA"
  fastboot reboot
  echo "RESTORE_STOCK_VBMETA_OK"
} 2>&1 | tee "$LOG"

read "?按回车关闭窗口。"
