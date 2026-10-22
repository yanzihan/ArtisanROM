# vold is critical and has reboot_on_failure; on this port it can fail on the
# first boot (data encryption/keymaster path) and would reboot the whole
# device. Keep the boot alive so the actual vold error can be inspected.
LOG_STEP_IN "- Relaxing vold auto-reboot (port workaround)"
VOLD_RC="$WORK_DIR/system/system/etc/init/vold.rc"
if [ -f "$VOLD_RC" ] && grep -q "reboot_on_failure reboot,vold-failed" "$VOLD_RC"; then
    sed -i '/reboot_on_failure reboot,vold-failed/d' "$VOLD_RC"
    LOG "- Removed vold reboot_on_failure"
else
    LOG "- vold reboot_on_failure not present; nothing to do"
fi
unset VOLD_RC
LOG_STEP_OUT
