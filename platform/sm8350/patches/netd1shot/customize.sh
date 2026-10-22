# netd1shot is a boot self-test used to trigger a mainline-module rollback.
# On this port it fails (the tethering/netd APEX and the 5.4 BPF backport do
# not satisfy the self-test), and its reboot_on_failure reboots the device
# forever instead of letting netd proper start. Disable the auto-reboot.
LOG_STEP_IN "- Relaxing netd1shot auto-reboot (port workaround)"
NETD_RC="$WORK_DIR/system/system/etc/init/netd.rc"
if [ -f "$NETD_RC" ] && grep -q "reboot_on_failure reboot,netd1shot-fail" "$NETD_RC"; then
    sed -i '/reboot_on_failure reboot,netd1shot-fail/d' "$NETD_RC"
    LOG "- Removed netd1shot reboot_on_failure"
else
    LOG "- netd1shot reboot_on_failure not present; nothing to do"
fi
unset NETD_RC
LOG_STEP_OUT
