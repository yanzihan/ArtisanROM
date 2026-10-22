# KernelSU (backslashxx fork manager, pairs with the non-GKI 5.4 kernel)
# v3.3.1-22 (32702): same signing cert (dummy keystore) and UAPI 6 as the
# 32700 kernel, verified on-device: manager upgrades keep root working.
KERNELSU_MANAGER_APK="https://github.com/backslashxx/KernelSU/releases/download/v3.3.1-22/KernelSU_v3.3.1-22_32702-release.apk"
# Samsung preload installer requires <package-name>==/base.apk layout
APK_PATH="system/preload/KernelSU/me.weishu.kernelsu==/base.apk"

LOG "- Adding KernelSU manager apk to preload apps"
mkdir -p "$WORK_DIR/system/$(dirname "$APK_PATH")"
if [ -f "$SRC_DIR/prebuilts/kernelsu/KernelSU_v3.3.1-22_32702.apk" ]; then
    LOG "- Using cached KernelSU manager"
    EVAL "cp -a \"$SRC_DIR/prebuilts/kernelsu/KernelSU_v3.3.1-22_32702.apk\" \"$WORK_DIR/system/$APK_PATH\""
else
    DOWNLOAD_FILE "$KERNELSU_MANAGER_APK" "$WORK_DIR/system/$APK_PATH"
fi

# Samsung Internet Browser
# https://play.google.com/store/apps/details?id=com.sec.android.app.sbrowser
LOG "- Downloading Samsung Internet app"
if [ -f "$SRC_DIR/prebuilts/sbrowser/SBrowser.apk" ]; then
    LOG "- Using cached Samsung Internet"
    mkdir -p "$WORK_DIR/system/system/preload/SBrowser"
    EVAL "cp -a \"$SRC_DIR/prebuilts/sbrowser/SBrowser.apk\" \"$WORK_DIR/system/system/preload/SBrowser/SBrowser.apk\""
else
    DOWNLOAD_FILE "$(GET_GALAXY_STORE_DOWNLOAD_URL "com.sec.android.app.sbrowser")" \
        "$WORK_DIR/system/system/preload/SBrowser/SBrowser.apk"
fi

while IFS= read -r i; do
    i="${i//$WORK_DIR\/system\//}"

    if [ -d "$WORK_DIR/system/$i" ]; then
        SET_METADATA "system" "$i" 0 0 755 "u:object_r:system_file:s0"
    else
        SET_METADATA "system" "$i" 0 0 644 "u:object_r:system_file:s0"
    fi

    if [[ "$i" == *".apk" ]] && \
            ! grep -q "$i" "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"; then
        LOG "- Adding \"$i\" to /system/system/etc/vpl_apks_count_list.txt"
        EVAL "echo \"$i\" >> \"$WORK_DIR/system/system/etc/vpl_apks_count_list.txt\""
    fi
done <<< "$(find "$WORK_DIR/system/system/preload")"
