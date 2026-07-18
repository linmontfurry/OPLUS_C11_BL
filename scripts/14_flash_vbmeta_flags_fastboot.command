#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/00_env.zsh"

FIX_ROOT="$A93S_ROOT/vbmeta_dmverity_fix"
VBMETA="$FIX_ROOT/vbmeta_stock.img"
LOG="$A93S_LOG_DIR/14_flash_vbmeta_flags_fastboot_$(date +%Y%m%d_%H%M%S).log"

banner "14_flash_vbmeta_flags_fastboot"
echo "Log: $LOG"
echo "目标：用原厂 vbmeta 刷入 disable-verity / disable-verification flags。"
echo "如果手机出现 Select Boot Mode：选 Fastboot Mode（音量上移动，音量下确认）。"

if [[ ! -s "$VBMETA" ]]; then
  echo "缺少 vbmeta 备份：$VBMETA"
  echo "先运行 13_read_vbmeta_mtk.command。"
  read "?按回车关闭窗口。"
  exit 1
fi

"$A93S_PY" - "$VBMETA" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
data = path.read_bytes()
if len(data) < 0x100 or data[:4] != b"AVB0":
    print(f"VBMETA_VALIDATE_FAIL: {path} size={len(data)} header={data[:4].hex()}")
    sys.exit(1)
print(f"VBMETA_VALIDATE_OK: {path} size={len(data)}")
PY

echo
echo "继续前输入：FLASH_VBMETA_FLAGS"
read "?确认码：" confirm
if [[ "$confirm" != "FLASH_VBMETA_FLAGS" ]]; then
  echo "确认码不对，停止。"
  read "?按回车关闭窗口。"
  exit 1
fi

{
  echo "ADB devices:"
  adb devices
  adb wait-for-device

  echo
  echo "当前状态："
  adb shell 'printf "device_state="; getprop ro.boot.vbmeta.device_state; printf "verifiedbootstate="; getprop ro.boot.verifiedbootstate; printf "veritymode="; getprop ro.boot.veritymode'

  echo
  echo "重启到 bootloader/fastboot..."
  adb reboot bootloader || true
  sleep 5

  echo "等待 fastboot。若看到 Select Boot Mode，请选 Fastboot Mode。"
  for i in {1..90}; do
    if fastboot devices | grep -q .; then
      break
    fi
    sleep 1
    printf "."
  done
  echo
  fastboot devices

  echo
  echo "刷入顶层 vbmeta disable flags。"
  fastboot --disable-verity --disable-verification flash vbmeta "$VBMETA"

  echo
  echo "重启。"
  fastboot reboot

  echo
  echo "FLASH_VBMETA_FLAGS_OK"
} 2>&1 | tee "$LOG"

echo
echo "开机后观察 dm-verity corruption 是否消失。"
echo "进系统后回 Codex 查状态。"
read "?按回车关闭窗口。"
