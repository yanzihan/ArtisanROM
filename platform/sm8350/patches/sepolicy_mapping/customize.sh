# One UI 9 (Android 17) ships SELinux mapping files only for vendor APIs
# 31+. p3q's vendor is API 30, so init's secilc fails on
# /system/etc/selinux/mapping/30.0.cil and aborts (InitFatalReboot).
# Restore the legacy mappings from the target (p3q) firmware.
LOG_STEP_IN "- Adding legacy SELinux vendor-API mappings"

TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
MAP_SRC="$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/selinux/mapping"
MAP_DST="$WORK_DIR/system/system/etc/selinux/mapping"

mkdir -p "$MAP_DST"
for f in 30.0.cil 30.0.compat.cil; do
    [ -f "$MAP_SRC/$f" ] || continue
    [ -f "$MAP_DST/$f" ] && continue
    cp -f "$MAP_SRC/$f" "$MAP_DST/$f"
    grep -q "system/etc/selinux/mapping/$f " "$WORK_DIR/configs/fs_config-system" 2> /dev/null || \
        echo "system/etc/selinux/mapping/$f 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
    esc="$(echo "$f" | sed 's/\./\\\\./g')"
    grep -q "/system/etc/selinux/mapping/$esc " "$WORK_DIR/configs/file_context-system" 2> /dev/null || \
        echo "/system/etc/selinux/mapping/$esc u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
    LOG "- Added mapping/$f from target firmware"
done
unset TARGET_FIRMWARE_PATH MAP_SRC MAP_DST f esc

LOG_STEP_OUT
