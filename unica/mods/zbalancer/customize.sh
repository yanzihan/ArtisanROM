# The S9280 (One UI 8.5) framework dexes ship right at the 65,535
# method-reference limit (classes.dex has 65,534 IDs, classes6 65,224).
# The Keybox/PIF/Settings hook mods add cross-dex references into
# classes.dex and classes3.dex, the keybox module moves BaseBundle into
# classes6 to free classes3, and the hook implementations themselves live in
# classes6. Give every affected dex headroom by relocating the moved
# classes and the hook classes into a dedicated new dex (classes8).
# Cross-dex references are resolved by the class loader, so only the dex
# container of each class changes.
FWJAR="$APKTOOL_DIR/system/framework/framework.jar"
for SRC in smali_classes3 smali_classes6; do
    if [ -f "$FWJAR/$SRC/android/os/BaseBundle.smali" ]; then
        LOG "- Relocating BaseBundle from $SRC to classes8"
        EVAL "mkdir -p \"$FWJAR/smali_classes8/android/os\""
        EVAL "mv \"$FWJAR/$SRC/android/os/BaseBundle.smali\" \"$FWJAR/smali_classes8/android/os/BaseBundle.smali\""
    fi
done
if [ -f "$FWJAR/smali/android/app/Instrumentation.smali" ]; then
    LOG "- Relocating Instrumentation from classes.dex to classes8"
    EVAL "mkdir -p \"$FWJAR/smali_classes8/android/app\""
    EVAL "mv \"$FWJAR/smali/android/app/Instrumentation.smali\" \"$FWJAR/smali_classes8/android/app/Instrumentation.smali\""
fi
if [ -d "$FWJAR/smali_classes6/io" ]; then
    LOG "- Relocating ROM hook classes from classes6 to classes8"
    EVAL "mkdir -p \"$FWJAR/smali_classes8/io\""
    EVAL "mv \"$FWJAR/smali_classes6/io/mesalabs\" \"$FWJAR/smali_classes8/io/mesalabs\""
    if [ -z "$(find "$FWJAR/smali_classes6/io" -mindepth 1 | head -n 1)" ]; then
        EVAL "rm -rf \"$FWJAR/smali_classes6/io\""
    fi
fi
