A93s / PFGM00 / MT6833 BL 脚本包

不要在 Codex 内置终端里输 sudo 密码。
直接双击这些 .command，或在 macOS Terminal 里运行。

核心原则：
1. 黑屏临时 LK 状态下，只需要发 unlock：01_black_pure_unlock.command
2. 原厂 LK 回滚只写 lk/lk2，不动 seccfg：02_restore_stock_lk.command
3. 如果需要重新制造教程里的“临时 unlock LK 黑屏态”，才运行：03_temp_unlock_lk_then_pure_unlock.command
4. 进系统后验证：04_verify_after_boot.command

推荐顺序：
1. 当前已经是原厂 LK 但黑屏/等待 unlock：
   运行 01_black_pure_unlock.command

2. 如果 01 后还黑屏：
   运行 02_restore_stock_lk.command
   拔线，长按电源 20–30 秒，再开机。

3. 如果 unlock 没写进去，需要完整重走教程第三步：
   运行 03_temp_unlock_lk_then_pure_unlock.command
   然后必须运行 02_restore_stock_lk.command

4. 如果恢复原厂 LK 后仍然 locked：
   运行 06_sync_only_unlock_then_BOOT_ONCE.command
   拔线后必须手动开机等 60 秒，让临时 LK 跑一次。
   然后再运行 02_restore_stock_lk.command。

新路线：preloader 开 fastboot，再走官方 fastboot unlock：
1. 运行 07_read_full_boot1.command
   读取完整 UFS boot1/LU1，必须得到 4194304 字节的 boot1_stock_full.bin。

2. 运行 08_build_fastboot_preloader.command
   用 Shocked-Cat/oppo-mtk-fastboot-unlock 逻辑生成 boot1_fastboot_unlock_candidate.bin。

3. 运行 09_flash_fastboot_preloader.command
   写入候选 boot1。注意这一步风险高于 LK，脚本会要求确认码。

4. 手机能进系统后，确认 开发者选项 -> OEM 解锁 已开启。
   然后运行 11_fastboot_unlock_official.command。

5. 如果刷入候选 boot1 后不开机/异常：
   运行 10_restore_stock_boot1.command 恢复完整原厂 boot1。

修复 dm-verity corruption 按电源提示：
1. 先试无刷分区命令 fastboot oem cdms；如果 unknown command，再走下一步。
2. 运行 12_fix_dm_verity_vbmeta_fastboot.command
   该脚本会先 fastboot fetch 备份顶层 vbmeta，再用 fastboot 内置 flags 刷回。
3. 如果 12 提示 Device does not support fetch command：
   运行 13_read_vbmeta_mtk.command 先用 MTK/BROM 备份 vbmeta。
   然后手机进系统，运行 14_flash_vbmeta_flags_fastboot.command。
4. 如果需要回滚顶层 vbmeta：
   运行 15_restore_stock_vbmeta_fastboot.command。

4. 出现橙色/Can't be trusted：
   等 5 秒，或按一下电源继续。

5. 能进 recovery：
   格式化数据分区，等待开机。
