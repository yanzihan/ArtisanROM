SET_PROP_IF_DIFF "vendor" "ro.oem_unlock_supported" "0"

# Disable FRP
SET_PROP "vendor" "ro.frp.pst" ""
SET_PROP "product" "ro.frp.pst" ""

# Better device/model detection in CoreRune
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali_classes6/com/samsung/android/rune/CoreRune.smali" "replace" \
    '<clinit>()V' \
    'ro.product.model' \
    'ro.product.vendor.model'
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali_classes6/com/samsung/android/rune/CoreRune.smali" "replace" \
    '<clinit>()V' \
    'ro.product.device' \
    'ro.product.vendor.device'

# shellcheck disable=SC2016
# Disable RescueParty
DECODE_APK "system" "system/framework/services.jar"
if [ -f "$APKTOOL_DIR/system/framework/services.jar/smali/com/android/server/RescueParty.smali" ]; then
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali/com/android/server/RescueParty.smali" "return" \
        '-$$Nest$smisDisabled()Z' \
        'true'
else
    LOGW "- RescueParty class not present in this base; skipping disable patch (TODO: SecRescueParty)"
fi

# Better model detection in FreecessController
SMALI_PATCH "system" "system/framework/services.jar" \
    "smali/com/android/server/am/FreecessController.smali" "replace" \
    '<clinit>()V' \
    'ro.product.model' \
    'ro.product.vendor.model'
    
LOG_STEP_IN "- Enabling BSOH in deviceinfo"
VALUE=${SOURCE_FIRMWARE:0:8}

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

for _NAME in BatteryRegulatoryPreferenceController.smali SecBatteryInfoFragment.smali; do
    _FILE="$(find "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk" -type f -name "$_NAME" -print -quit)"
    [ -n "$_FILE" ] && sed -i "s/SM-A236B/$VALUE/g" "$_FILE"
done
unset _NAME _FILE

LOG_STEP_OUT
