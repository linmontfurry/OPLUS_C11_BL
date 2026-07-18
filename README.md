# OPLUS_C11_BL
小凛莫使用的oppo解锁方案备份


# 目录说明：
- stock_images/: 原厂/救砖基础镜像，包含 boot/lk/lk2/preloader RAW/seccfg。
- preloader_fastboot_unlock/: 完整 UFS boot1 原厂备份与 fastboot-unlock 候选。
- vbmeta_dmverity_fix/: 原厂 vbmeta / vbmeta_system / vbmeta_vendor 备份。
- scripts/: 自包含脚本，已改为使用本备份包内 tools/mtkclient。
- gpt/: GPT 备份。
- tools/: mtkclient 与 OPPO MTK fastboot unlock preloader 补丁器源码。
- logs_reference/: 关键成功日志。

最重要的文件：
1. preloader_fastboot_unlock/boot1_stock_full.bin
2. preloader_fastboot_unlock/boot1_fastboot_unlock_candidate.bin
3. vbmeta_dmverity_fix/vbmeta_stock.img
4. vbmeta_dmverity_fix/vbmeta_system_stock.img
5. vbmeta_dmverity_fix/vbmeta_vendor_stock.img
6. stock_images/boot_stock.img
7. stock_images/lk_stock.img
8. stock_images/lk2_stock.img

常用脚本：
- scripts/04_verify_after_boot.command：进系统后检查 BL 状态。
- scripts/02_restore_stock_lk.command：恢复原厂 lk/lk2。
- scripts/10_restore_stock_boot1.command：恢复原厂完整 boot1。
- scripts/09_flash_fastboot_preloader.command：重新写入 fastboot-unlock boot1 候选。
- scripts/14_flash_vbmeta_flags_fastboot.command：修 dm-verity corruption 提示。
- scripts/15_restore_stock_vbmeta_fastboot.command：恢复原厂顶层 vbmeta。

注意：不要在修改过系统/root/boot/vbmeta 后执行 fastboot flashing lock。
