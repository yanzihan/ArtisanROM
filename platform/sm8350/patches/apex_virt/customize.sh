# One UI 9's prebuilt com.android.virt APEX payload is EROFS with
# COMPR_CFGS (incompat feature 2), which the 5.4 kernel's EROFS cannot mount.
# apexd-bootstrap then fails and init reboots with bootstrap-apexd-failed.
# p3q cannot run Microdroid/virtualization anyway, so drop the APEX instead
# of backporting the EROFS feature.
LOG_STEP_IN "- Removing com.android.virt APEX (EROFS feature 2 unsupported by 5.4)"
if [ -f "$WORK_DIR/system/system/apex/com.android.virt.apex" ]; then
    DELETE_FROM_WORK_DIR "system" "system/apex/com.android.virt.apex"
    LOG "- Removed /system/system/apex/com.android.virt.apex"
else
    LOG "- com.android.virt APEX not present; nothing to do"
fi
LOG_STEP_OUT
