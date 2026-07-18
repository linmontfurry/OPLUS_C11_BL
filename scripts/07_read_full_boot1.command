#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/00_env.zsh"

BOOT1_DIR="$A93S_ROOT/preloader_fastboot_unlock"
mkdir -p "$BOOT1_DIR"

STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="$BOOT1_DIR/boot1_stock_full_$STAMP.bin"
STABLE="$BOOT1_DIR/boot1_stock_full.bin"
LOG="$A93S_LOG_DIR/07_read_full_boot1_$STAMP.log"
ATTEMPT="$A93S_LOG_DIR/07_read_full_boot1_attempt.tmp"

banner "07_read_full_boot1"
echo "Log: $LOG"
echo "目标：读取完整 UFS boot1/LU1，大小必须是 0x400000。"
wait_hint

while true; do
  echo "--- $(date '+%Y-%m-%d %H:%M:%S') attempt ---" | tee -a "$LOG"
  set +e
  sudo "$A93S_PY" "$A93S_MTK" rf --parttype boot1 "$OUT" --length 0x400000 2>&1 | tee "$ATTEMPT"
  code=${pipestatus[1]}
  set -e
  cat "$ATTEMPT" >> "$LOG"

  if [[ "$code" == 0 && -f "$OUT" ]]; then
    size="$(stat -f %z "$OUT")"
    if [[ "$size" == "4194304" ]]; then
      "$A93S_PY" - "$OUT" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
data = path.read_bytes()
if not (data.startswith(b"UFS_BOOT") or data.startswith(b"EMMC_BOOT") or data.startswith(b"COMBO_BOOT")):
    print(f"BOOT1_VALIDATE_FAIL: unexpected header {data[:16].hex()}")
    sys.exit(1)
if b"AND_ROMINFO_v" not in data:
    print("BOOT1_VALIDATE_FAIL: AND_ROMINFO_v flag block not found")
    sys.exit(1)
print("BOOT1_VALIDATE_OK")
PY
      cp -p "$OUT" "$STABLE"
      shasum -a 256 "$OUT" "$STABLE" | tee -a "$LOG"
      echo "READ_FULL_BOOT1_OK: $STABLE" | tee -a "$LOG"
      break
    fi
    echo "读取文件大小不对：$size，期望 4194304。" | tee -a "$LOG"
  fi

  echo "未成功，3 秒后重试。拔线，等 Waiting，再三键插线。" | tee -a "$LOG"
  sleep 3
done

echo
echo "下一步：运行 08_build_fastboot_preloader.command。"
read "?按回车关闭窗口。"
