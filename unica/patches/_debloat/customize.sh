# shellcheck disable=SC2016

# Dexpreopt
find "$WORK_DIR/product" -type d -name "oat" -print0 | xargs -0 -I "{}" -P "$(nproc)" \
    bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "product" "${1//$WORK_DIR\/product\//}"' "bash" "{}"
find "$WORK_DIR/system" -type d -name "oat" -print0 | xargs -0 -I "{}" -P "$(nproc)" \
    bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "system" "${1//$WORK_DIR\/system\//}"' "bash" "{}"
# One UI 9 / Android 17: keep the prebuilt boot images and profiles. odrefresh/art_boot
# cannot regenerate them on this port (odsign needs a working TEE/keystore), and zygote
# aborts when both the image and boot-image.prof are missing.
if [ "$SOURCE_PLATFORM_SDK_VERSION" -lt 37 ]; then
    DELETE_FROM_WORK_DIR "system" "system/etc/boot-image.bprof"
    DELETE_FROM_WORK_DIR "system" "system/etc/boot-image.prof"
    DELETE_FROM_WORK_DIR "system" "system/framework/arm"
    DELETE_FROM_WORK_DIR "system" "system/framework/arm64"
    find "$WORK_DIR/system/system/framework" -type f -name "*.vdex" -print0 | xargs -0 -I "{}" -P "$(nproc)" \
        bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "system" "${1//$WORK_DIR\/system\//}"' "bash" "{}"
fi
if $TARGET_OS_BUILD_SYSTEM_EXT_PARTITION; then
    find "$WORK_DIR/system_ext" -type d -name "oat" -print0 | xargs -0 -I "{}" -P "$(nproc)" \
        bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "system_ext" "${1//$WORK_DIR\/system_ext\//}"' "bash" "{}"
fi

# ROM & device-specific debloat list
if [ -f "$SRC_DIR/unica/debloat.sh" ]; then
    source "$SRC_DIR/unica/debloat.sh"
fi
if [ -f "$SRC_DIR/platform/$TARGET_PLATFORM/debloat.sh" ]; then
    source "$SRC_DIR/platform/$TARGET_PLATFORM/debloat.sh"
fi
if [ -f "$SRC_DIR/target/$TARGET_CODENAME/debloat.sh" ]; then
    source "$SRC_DIR/target/$TARGET_CODENAME/debloat.sh"
fi

ODM_DEBLOAT="$(sed "/^$/d" <<< "$ODM_DEBLOAT" | sort)"
PRODUCT_DEBLOAT="$(sed "/^$/d" <<< "$PRODUCT_DEBLOAT" | sort)"
SYSTEM_DEBLOAT="$(sed "/^$/d" <<< "$SYSTEM_DEBLOAT" | sort)"
SYSTEM_EXT_DEBLOAT="$(sed "/^$/d" <<< "$SYSTEM_EXT_DEBLOAT" | sort)"
VENDOR_DEBLOAT="$(sed "/^$/d" <<< "$VENDOR_DEBLOAT" | sort)"

if [ "$ODM_DEBLOAT" ]; then
    xargs -I "{}" -P "$(nproc)" \
        bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "odm" "$1"' "bash" "{}" \
        <<< "$ODM_DEBLOAT" 2>&1 | sed "/File not found/d"
fi
if [ "$PRODUCT_DEBLOAT" ]; then
    xargs -I "{}" -P "$(nproc)" \
        bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "product" "$1"' "bash" "{}" \
        <<< "$PRODUCT_DEBLOAT" 2>&1 | sed "/File not found/d"
fi
if [ "$SYSTEM_DEBLOAT" ]; then
    xargs -I "{}" -P "$(nproc)" \
        bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "system" "$1"' "bash" "{}" \
        <<< "$SYSTEM_DEBLOAT" 2>&1 | sed "/File not found/d"
fi
if [ "$SYSTEM_EXT_DEBLOAT" ]; then
    xargs -I "{}" -P "$(nproc)" \
        bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "system_ext" "$1"' "bash" "{}" \
        <<< "$SYSTEM_EXT_DEBLOAT" 2>&1 | sed "/File not found/d"
fi
if [ "$VENDOR_DEBLOAT" ]; then
    xargs -I "{}" -P "$(nproc)" \
        bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "vendor" "$1"' "bash" "{}" \
        <<< "$VENDOR_DEBLOAT" 2>&1 | sed "/File not found/d"
fi

unset ODM_DEBLOAT PRODUCT_DEBLOAT SYSTEM_DEBLOAT SYSTEM_EXT_DEBLOAT VENDOR_DEBLOAT
