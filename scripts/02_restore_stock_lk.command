#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/00_env.zsh"
require_files

LK="$A93S_ROOT/stock_images/lk_stock.img"
LK2="$A93S_ROOT/stock_images/lk2_stock.img"

run_loop \
  "02_restore_stock_lk" \
  "w lk,lk2 $LK,$LK2;reset" \
  "RESTORE_STOCK_LK_OK" \
  "Wrote $LK2"

echo
echo "下一步：拔线，长按电源 20–30 秒，再单按电源。"
read "?按回车关闭窗口。"
