echo "Fix up /product/etc/build.prop"
sed -i "/# Removed by /d" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "s/#bluetooth./bluetooth./g" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "s/?=/=/g" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "$(sed -n "/provisioning.hostname/=" "$WORK_DIR/product/etc/build.prop" | sed "2p;d")d" "$WORK_DIR/product/etc/build.prop"

# The G9980 (5.4-qgki) kernel has no schedtune cgroup controller, but its
# vendor cgroups.json still declares one. Android 16 init mounts every
# controller declared in cgroups.json during SetupCgroups; the failed mount
# makes apexd bootstrap fail and triggers a bootloop (bootstrap-apexd-failed).
LOG_STEP_IN "- Removing unsupported schedtune cgroup from vendor cgroups.json"
printf '%s\n' '{ "Cgroups": [] }' > "$WORK_DIR/vendor/etc/cgroups.json"
LOG_STEP_OUT

# The 5.4 target kernel is below the 5.10 floor enforced by netbpfload
# ("Android 25Q4 requires kernel 5.10"), and bpfloader failing would crash
# netd -> system_server in a bootloop. Ship a netbpfload with the version
# gate patched out (the per-object kernel-version skips still apply) inside
# a re-signed tethering APEX.
LOG_STEP_IN "- Installing tethering APEX with patched netbpfload"
DELETE_FROM_WORK_DIR "system" "system/apex/com.google.android.tethering_compressed.apex"
EVAL "cp -a \"$MODPATH/com.android.tethering.apex\" \"$WORK_DIR/system/system/apex/com.android.tethering.apex\""
SET_METADATA "system" "system/apex/com.android.tethering.apex" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

# f2fs checkpoint rollback runs fsck against the mounted /data on this
# fs_mgr version; drop the flag so the first mount is the only mount.
LOG_STEP_IN "- Dropping checkpoint=fs from the userdata mount flags"
for FSTAB in "$WORK_DIR/vendor/etc/fstab.default" "$WORK_DIR/vendor/etc/fstab.emmc"; do
    [ -f "$FSTAB" ] || continue
    sed -i '/by-name\/userdata/s/,checkpoint=fs//' "$FSTAB"
done
LOG_STEP_OUT
