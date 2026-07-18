#!/bin/zsh
set -euo pipefail

echo "目标：用已打开的 OPPO fastboot 通道执行官方 unlock。"
echo "前提：系统里已经打开 开发者选项 -> OEM 解锁。"
echo

adb wait-for-device
echo "ADB device:"
adb devices

echo
echo "重启到 bootloader/fastboot。"
adb reboot bootloader
sleep 8

echo "等待 fastboot。"
fastboot devices

echo
echo "执行 fastboot flashing unlock。"
echo "手机屏幕出现确认时，用音量键选择确认，再按电源键。"
fastboot flashing unlock

echo
echo "如果命令完成，手机通常会清数据并重启。进系统后运行 04_verify_after_boot.command。"
read "?按回车关闭窗口。"
