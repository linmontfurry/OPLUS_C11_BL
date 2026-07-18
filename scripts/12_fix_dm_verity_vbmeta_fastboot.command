#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/00_env.zsh"

OUT_DIR="$A93S_ROOT/vbmeta_dmverity_fix/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT_DIR"
LOG="$A93S_LOG_DIR/12_fix_dm_verity_vbmeta_fastboot_$(date +%Y%m%d_%H%M%S).log"

banner "12_fix_dm_verity_vbmeta_fastboot"
echo "Log: $LOG"
echo "目标：备份原厂 vbmeta，然后刷入带 disable-verity / disable-verification flags 的 vbmeta。"
echo "这一步只碰顶层 vbmeta，不碰 system/vendor。"
echo
echo "如果手机出现 Select Boot Mode：选 Fastboot Mode（音量上移动，音量下确认）。"
echo
echo "继续前输入：FIX_DM_VERITY"
read "?确认码：" confirm
if [[ "$confirm" != "FIX_DM_VERITY" ]]; then
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
  echo "备份 vbmeta：$OUT_DIR/vbmeta_stock.img"
  fastboot fetch vbmeta "$OUT_DIR/vbmeta_stock.img"
  test -s "$OUT_DIR/vbmeta_stock.img"
  shasum -a 256 "$OUT_DIR/vbmeta_stock.img"

  echo
  echo "尝试同时备份 vbmeta_system / vbmeta_vendor（失败不影响顶层修复）。"
  fastboot fetch vbmeta_system "$OUT_DIR/vbmeta_system_stock.img" || true
  fastboot fetch vbmeta_vendor "$OUT_DIR/vbmeta_vendor_stock.img" || true
  find "$OUT_DIR" -type f -maxdepth 1 -print -exec shasum -a 256 {} \\;

  echo
  echo "刷入顶层 vbmeta disable flags。"
  fastboot --disable-verity --disable-verification flash vbmeta "$OUT_DIR/vbmeta_stock.img"

  echo
  echo "重启。"
  fastboot reboot

  echo
  echo "VMBETA_DM_VERITY_FLAGS_FLASHED"
} 2>&1 | tee "$LOG"

echo
echo "开机后观察 dm-verity corruption 是否消失。"
echo "进系统后运行 04_verify_after_boot.command 或直接回 Codex 查状态。"
read "?按回车关闭窗口。"
