#!/bin/zsh
set -euo pipefail

echo "等待 ADB 设备。手机进系统后保持 USB 调试允许。"
adb wait-for-device

adb shell 'printf "ro.boot.flash.locked="; getprop ro.boot.flash.locked'
adb shell 'printf "ro.boot.vbmeta.device_state="; getprop ro.boot.vbmeta.device_state'
adb shell 'printf "ro.boot.verifiedbootstate="; getprop ro.boot.verifiedbootstate'
adb shell 'printf "sys.boot_completed="; getprop sys.boot_completed'

echo
echo "期望 unlocked：flash.locked=0 / vbmeta.device_state=unlocked / verifiedbootstate=orange"
read "?按回车关闭窗口。"
