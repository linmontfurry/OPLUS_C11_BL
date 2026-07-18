#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/00_env.zsh"

BOOT1_DIR="$A93S_ROOT/preloader_fastboot_unlock"
TOOL_DIR="$A93S_ROOT/oppo_mtk_fastboot_unlock_tool"
SRC="$BOOT1_DIR/boot1_stock_full.bin"
CAND="$BOOT1_DIR/boot1_fastboot_unlock_candidate.bin"
LOG="$A93S_LOG_DIR/08_build_fastboot_preloader_$(date +%Y%m%d_%H%M%S).log"

banner "08_build_fastboot_preloader"
echo "Log: $LOG"

if [[ ! -f "$SRC" ]]; then
  echo "缺少完整 boot1：$SRC"
  echo "先运行 07_read_full_boot1.command。"
  read "?按回车关闭窗口。"
  exit 1
fi

"$A93S_PY" - "$SRC" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
data = path.read_bytes()
if len(data) != 0x400000:
    print(f"BOOT1_VALIDATE_FAIL: size={len(data):#x}, expected 0x400000")
    sys.exit(1)
if not (data.startswith(b"UFS_BOOT") or data.startswith(b"EMMC_BOOT") or data.startswith(b"COMBO_BOOT")):
    print(f"BOOT1_VALIDATE_FAIL: unexpected header {data[:16].hex()}")
    sys.exit(1)
flag_at = data.find(b"AND_ROMINFO_v")
if flag_at < 0:
    print("BOOT1_VALIDATE_FAIL: AND_ROMINFO_v flag block not found")
    sys.exit(1)
print(f"BOOT1_VALIDATE_OK: flag_at=0x{flag_at:x}, fastboot_lock=0x{data[flag_at + 0x4c]:02x}")
PY

mkdir -p "$TOOL_DIR"
if [[ ! -f "$TOOL_DIR/path_preloader.py" ]]; then
  echo "首次使用：拉取 Shocked-Cat/oppo-mtk-fastboot-unlock。" | tee -a "$LOG"
  git clone --depth 1 https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock.git "$TOOL_DIR" 2>&1 | tee -a "$LOG"
else
  echo "使用已有工具：$TOOL_DIR" | tee -a "$LOG"
fi

WORK="$BOOT1_DIR/patch_work_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORK"
cd "$WORK"

printf '\n' | "$A93S_PY" "$TOOL_DIR/path_preloader.py" "$SRC" boot1_fastboot_unlock_candidate.bin 2>&1 | tee -a "$LOG"
OUT="$WORK/preloader_path/boot1_fastboot_unlock_candidate.bin"

if [[ ! -f "$OUT" ]]; then
  echo "生成失败：没有输出 $OUT" | tee -a "$LOG"
  read "?按回车关闭窗口。"
  exit 1
fi

"$A93S_PY" - "$SRC" "$OUT" <<'PY'
from pathlib import Path
import sys

src = Path(sys.argv[1])
out = Path(sys.argv[2])
original = src.read_bytes()
patched = out.read_bytes()
if len(patched) != 0x400000:
    print(f"PATCH_VALIDATE_FAIL: size={len(patched):#x}, expected 0x400000")
    sys.exit(1)
if patched == original:
    print("PATCH_VALIDATE_FAIL: candidate equals stock")
    sys.exit(1)
if patched[0x104c] != 0:
    print(f"PATCH_VALIDATE_FAIL: 0x104c={patched[0x104c]:#x}, expected 0")
    sys.exit(1)
if not (patched[0x20d] == 0x20 and patched[0x21d] == 0x20 and patched[0x211] == 0x10 and patched[0x212] == 0x10 and patched[0x221] == 0x10 and patched[0x222] == 0x10):
    print("PATCH_VALIDATE_FAIL: BRLYT offsets do not match expected patch")
    sys.exit(1)
print("PATCH_VALIDATE_OK")
PY

cp -p "$OUT" "$CAND"
shasum -a 256 "$SRC" "$CAND" | tee -a "$LOG"
cmp -l "$SRC" "$CAND" | sed -n '1,80p' > "$BOOT1_DIR/boot1_candidate_cmp_first80.txt" || true
echo "BUILD_FASTBOOT_PRELOADER_OK: $CAND" | tee -a "$LOG"

echo
echo "下一步：运行 09_flash_fastboot_preloader.command。"
read "?按回车关闭窗口。"
