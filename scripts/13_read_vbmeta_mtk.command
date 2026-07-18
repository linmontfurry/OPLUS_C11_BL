#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/00_env.zsh"

FIX_ROOT="$A93S_ROOT/vbmeta_dmverity_fix"
OUT_DIR="$FIX_ROOT/mtk_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT_DIR"
LOG="$A93S_LOG_DIR/13_read_vbmeta_mtk_$(date +%Y%m%d_%H%M%S).log"
ATTEMPT="$A93S_LOG_DIR/13_read_vbmeta_mtk_attempt.tmp"

VBMETA="$OUT_DIR/vbmeta_stock.img"
VBMETA_SYSTEM="$OUT_DIR/vbmeta_system_stock.img"
VBMETA_VENDOR="$OUT_DIR/vbmeta_vendor_stock.img"

banner "13_read_vbmeta_mtk"
echo "Log: $LOG"
echo "目标：用 MTK/BROM 备份 vbmeta / vbmeta_system / vbmeta_vendor。"
echo "如果刚才停在 fastboot，请拔线，长按电源约 20 秒让它黑屏。"
wait_hint

while true; do
  echo "--- $(date '+%Y-%m-%d %H:%M:%S') attempt ---" | tee -a "$LOG"
  set +e
  sudo "$A93S_PY" "$A93S_MTK" multi "r vbmeta,vbmeta_system,vbmeta_vendor $VBMETA,$VBMETA_SYSTEM,$VBMETA_VENDOR;reset" 2>&1 | tee "$ATTEMPT"
  code=${pipestatus[1]}
  set -e
  cat "$ATTEMPT" >> "$LOG"

  if [[ "$code" == 0 && -s "$VBMETA" ]]; then
    "$A93S_PY" - "$VBMETA" "$VBMETA_SYSTEM" "$VBMETA_VENDOR" <<'PY'
from pathlib import Path
import sys

ok = True
for name in sys.argv[1:]:
    path = Path(name)
    if not path.exists() or path.stat().st_size == 0:
        print(f"VBMETA_VALIDATE_WARN: missing/empty {path}")
        continue
    data = path.read_bytes()[:4]
    if data != b"AVB0":
        print(f"VBMETA_VALIDATE_FAIL: {path} header={data.hex()}")
        ok = False
    else:
        print(f"VBMETA_VALIDATE_OK: {path} size={path.stat().st_size}")
if not ok:
    sys.exit(1)
PY
    cp -p "$VBMETA" "$FIX_ROOT/vbmeta_stock.img"
    [[ -s "$VBMETA_SYSTEM" ]] && cp -p "$VBMETA_SYSTEM" "$FIX_ROOT/vbmeta_system_stock.img" || true
    [[ -s "$VBMETA_VENDOR" ]] && cp -p "$VBMETA_VENDOR" "$FIX_ROOT/vbmeta_vendor_stock.img" || true
    echo "$OUT_DIR" > "$FIX_ROOT/latest_mtk_vbmeta_dir.txt"
    shasum -a 256 "$OUT_DIR"/*.img "$FIX_ROOT"/vbmeta*.img 2>/dev/null | tee -a "$LOG"
    echo "READ_VBMETA_MTK_OK: $FIX_ROOT/vbmeta_stock.img" | tee -a "$LOG"
    break
  fi

  echo "未成功，3 秒后重试。拔线，等 Waiting，再三键插线。" | tee -a "$LOG"
  sleep 3
done

echo
echo "下一步：让手机正常进系统并保持 ADB，然后运行 14_flash_vbmeta_flags_fastboot.command。"
read "?按回车关闭窗口。"
