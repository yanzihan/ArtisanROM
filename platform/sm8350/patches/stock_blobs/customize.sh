# p3q stock blobs. The 8250 tree sourced these from r9qxxx/a73xqxxx/pa1qxxx
# donors; G9980's own Android 15 firmware ships every one of them, so use
# $TARGET_FIRMWARE everywhere. (The S24U framework vintf manifest and NFC
# JNI set are already correct for p3q — S24U itself uses the same nfc_nci_nxpsn
# vendor stack — so no replacements.)

LOG_STEP_IN "- Fixing libhwui V-ndk dependencies"
# The source libhwui can reference frozen AIDL NDK libs (e.g. graphics.common-V6)
# that a newer source no longer ships. Frozen AIDL versions are supersets with
# the same symbols, so point each missing -V<n>-ndk dependency at the highest
# version the source has. Without this zygote, bootanimation and mediaserver
# fail to link libhwui and the device hangs at boot.
for LIBDIR in lib lib64; do
    HWUI="$WORK_DIR/system/system/$LIBDIR/libhwui.so"
    [ -f "$HWUI" ] || continue
    while read -r NEEDED; do
        [ -e "$WORK_DIR/system/system/$LIBDIR/$NEEDED" ] && continue
        BASE="${NEEDED%-V*-ndk.so}"
        NEWEST="$(find "$WORK_DIR/system/system/$LIBDIR" -maxdepth 1 -name "$BASE-V*-ndk.so" -printf '%f\n' 2> /dev/null | sort -V | tail -n 1)"
        if [ -n "$NEWEST" ]; then
            LOG "- $LIBDIR/libhwui.so: $NEEDED -> $NEWEST"
            EVAL "patchelf --replace-needed \"$NEEDED\" \"$NEWEST\" \"$HWUI\""
        else
            LOGW "- $LIBDIR/libhwui.so needs $NEEDED, which the source does not provide"
        fi
    done < <(readelf -d "$HWUI" | sed -n 's/.*(NEEDED).*\[\(.*-V[0-9]*-ndk\.so\)\].*/\1/p')
done
unset LIBDIR HWUI NEEDED BASE NEWEST
LOG_STEP_OUT

DELETE_FROM_WORK_DIR "system" "system/etc/permissions/com.sec.feature.cover.clearcameraviewcover.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/com.sec.feature.cover.flip.xml"
LOG_STEP_IN "- Add stock system features"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.clearsideviewcover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.sview.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.nfc_authentication_cover.xml" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Add stock GameDriver"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/GameDriver-SM8350/GameDriver-SM8350.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding stock 32-bit keymaster libs"
DELETE_FROM_WORK_DIR "system" "system/lib/android.hardware.security.secureclock-V1-ndk.so"
DELETE_FROM_WORK_DIR "system" "system/lib/libdk_native_keymint.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libdk_native_keymint.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/android.hardware.keymaster@3.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/android.hardware.keymaster@4.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/android.hardware.keymaster@4.1.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/lib_nativeJni.dk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libdk_native_keymaster.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libkeymaster4_1support.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libkeymaster4support.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_nativeJni.dk.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libdk_native_keymaster.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding stock MIDAS/AI/camera libs"
# libSwIsp_* is already added by the camera module; only the remaining set here.
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libSlowShutter_jni.media.samsung.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_nativeJni.dk.samsung.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsung_videoengine_9_0.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libtensorflowLite.camera.samsung.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libtensorflowlite_inference_api.camera.samsung.so"
LOG_STEP_OUT

LOG_STEP_IN "- Fixing Google Assistant"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentOKGoogleEx4HEXAGON"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentXGoogleEx4HEXAGON"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentOKGoogleEx3HEXAGON"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentXGoogleEx3HEXAGON"
LOG_STEP_OUT
