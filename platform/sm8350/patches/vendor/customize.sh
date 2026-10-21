# sm8350/p3q vendor adaptations. Kept minimal on purpose: p3q's stock vendor
# already ships AIDL vibrator V3, light-service, wpa_supplicant, the 32-bit
# WFD set, singletake models etc., so all the donor-blob replacements from
# the 8250 tree are unnecessary here and were removed.

echo "Remove DualDAR mount points"
# sm8350 targets use fstab.default/fstab.emmc instead of fstab.qcom
for FSTAB in "$WORK_DIR/vendor/etc/fstab.default" "$WORK_DIR/vendor/etc/fstab.emmc"; do
    [ -f "$FSTAB" ] || continue
    sed -i "/keydata/d" "$FSTAB"
    sed -i "/keyrefuge/d" "$FSTAB"
done

LOG_STEP_IN "- Setting Adaptive HFR flags"
    SET_PROP "vendor" "debug.sf.show_refresh_rate_overlay_render_rate" "true"
    SET_PROP "vendor" "ro.surface_flinger.game_default_frame_rate_override" "60"
    SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
    SET_PROP "vendor" "ro.surface_flinger.set_idle_timer_ms" "250"
    SET_PROP "vendor" "ro.surface_flinger.set_touch_timer_ms" "300"
    SET_PROP "vendor" "ro.surface_flinger.set_display_power_timer_ms" "200"
    SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"
LOG_STEP_OUT

LOG_STEP_IN "- Enabling Vulkan"
SET_PROP "vendor" "ro.hwui.use_vulkan" "true"
LOG_STEP_OUT

LOG_STEP_IN "- wifi+security Prop"
SET_PROP "vendor" "wlan.wfd.hdcp" "disabled"
SET_PROP "vendor" "wifi.interface" "wlan0"
SET_PROP "vendor" "ro.security.vaultkeeper.native" "0"
SET_PROP "vendor" "ro.security.vaultkeeper.feature" "0"
LOG_STEP_OUT

LOG_STEP_IN "- Configuring userdata mount (single unencrypted record)"
# Both fstab.default and fstab.emmc ship a userdata record and Samsung's
# fs_mgr processes BOTH files. With more than one record, the second mount
# attempt hits EBUSY, fs_mgr_mount_all() returns an error, init never fires
# the "nonencrypted" event and class_start main (installd and friends) never
# runs, so the boot hangs forever on the boot animation.
# Keep exactly ONE userdata record, in fstab.default, unencrypted.
for FSTAB in "$WORK_DIR/vendor/etc/fstab.default" "$WORK_DIR/vendor/etc/fstab.emmc"; do
    [ -f "$FSTAB" ] || continue
    sed -i '\|/dev/block/bootdevice/by-name/userdata|d' "$FSTAB"
done
printf '%s\n' '/dev/block/bootdevice/by-name/userdata                 /data                  f2fs    noatime,nosuid,nodev,discard,usrquota,grpquota,fsync_mode=nobarrier,reserve_root=32768,resgid=5678,inlinecrypt    latemount,wait,encryptable,keydirectory=/metadata/vold/metadata_encryption,sysfs_path=/sys/devices/platform/soc/1d84000.ufshc,quota,reservedsize=128M' \
    >> "$WORK_DIR/vendor/etc/fstab.default"
LOG_STEP_OUT

LOG_STEP_IN "- Allowing mremap in vendor Codec2 seccomp policies"
C2_POLICY_FIRST=""
C2_POLICY_PATCHED=false
while IFS= read -r f; do
    [ -z "$C2_POLICY_FIRST" ] && C2_POLICY_FIRST="$f"
    if grep -q "^mremap:" "$f"; then
        sed -i 's/^mremap:.*/mremap: 1/' "$f"
        C2_POLICY_PATCHED=true
        LOG "- Relaxed mremap rule in $(basename "$f")"
    fi
done < <(find "$WORK_DIR/vendor/etc/seccomp_policy" -type f \( -iname "*c2*" -o -iname "*codec2*" \) 2> /dev/null)
if ! $C2_POLICY_PATCHED; then
    if [ -n "$C2_POLICY_FIRST" ]; then
        [ -n "$(tail -c1 "$C2_POLICY_FIRST")" ] && echo >> "$C2_POLICY_FIRST"
        echo "mremap: 1" >> "$C2_POLICY_FIRST"
        LOG "- Added mremap to $(basename "$C2_POLICY_FIRST")"
    else
        LOGW "No Codec2 seccomp policy found in vendor/etc/seccomp_policy"
    fi
fi
unset C2_POLICY_FIRST C2_POLICY_PATCHED
LOG_STEP_OUT

LOG_STEP_IN "- Removing 24-bit deep_buffer output (fixes no media sound on speaker)"
sed -i '/<mixPort name="deep_buffer"/,/<\/mixPort>/d' "$WORK_DIR/vendor/etc/audio_policy_configuration_base.xml"
sed -i 's/deep_buffer,//g' "$WORK_DIR/vendor/etc/audio_policy_configuration_base.xml"
LOG_STEP_OUT

# The source-side HDCP key provisioning daemon (qchdcpkprov) NULL-derefs
# against the G9980 TEE firmware. Factory provisioning is not needed on a
# ported device, so disable the triggering service.
LOG_STEP_IN "- Disabling HDCP key provisioning service"
sed -i 's/^service SehHdcpKeyProvisioning-1-0 /#SEC_DISABLED service SehHdcpKeyProvisioning-1-0 /' \
    "$WORK_DIR/vendor/etc/init/vendor.samsung.hardware.security.hdcp.keyprovisioning@1.0-service.rc"
LOG_STEP_OUT

# The S24U camera app reads the VENDOR floating feature VENDOR_LIB_INFO (it
# overrides the system one); p3q's vendor file lacks the image_codec node
# feature entirely, which crashes the camera PostProcessThread on zoom shots.
VENDOR_FF="$WORK_DIR/vendor/etc/floating_feature.xml"
VENDOR_LIB_INFO="$(grep -o '<SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO>[^<]*' "$VENDOR_FF" | sed 's/.*>//')"
if [[ "$VENDOR_LIB_INFO" != *"image_codec"* ]]; then
    sed -i "s|$VENDOR_LIB_INFO|$VENDOR_LIB_INFO,image_codec.samsung.v1|" "$VENDOR_FF"
fi
