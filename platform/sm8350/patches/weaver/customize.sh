# p3q-specific framework patch: the S24U framework's SyntheticPasswordManager
# calls IWeaver.getService(true), which BLOCKS forever when the device has no
# weaver HAL (p3q's TEE reports "weaver unsupported"). system_server then hangs
# in checkWeaverStatus() at boot, the watchdog kills it, and the boot loops on
# the animation. Patch the call to getService(false) so it returns null fast
# and the existing "weaver NOT available" path is taken.

LOG_STEP_IN "- Patching SyntheticPasswordManager weaver lookup"

SERVICES_JAR="$WORK_DIR/system/system/framework/services.jar"
[ -f "$SERVICES_JAR" ] || { LOGE "services.jar not found"; exit 1; }

command -v baksmali > /dev/null 2>&1 || { LOGE "baksmali not found in PATH"; exit 1; }
command -v smali > /dev/null 2>&1 || { LOGE "smali not found in PATH"; exit 1; }

WEAVER_TMP="$TMP_DIR/weaver_patch"
rm -rf "$WEAVER_TMP"
mkdir -p "$WEAVER_TMP/extracted" "$WEAVER_TMP/smali"

EVAL "unzip -o -q \"$SERVICES_JAR\" \"classes*.dex\" -d \"$WEAVER_TMP/extracted\"" || exit 1

TARGET_DEX=""
for DEX in "$WEAVER_TMP/extracted"/classes*.dex; do
    [ -f "$DEX" ] || continue
    if grep -aq "SyntheticPasswordManager" "$DEX"; then
        TARGET_DEX="$(basename "$DEX")"
        break
    fi
done
[ -n "$TARGET_DEX" ] || { LOGE "SyntheticPasswordManager not found in services.jar"; exit 1; }

EVAL "baksmali d \"$WEAVER_TMP/extracted/$TARGET_DEX\" -o \"$WEAVER_TMP/smali\"" || exit 1

SMALI_FILE="$WEAVER_TMP/smali/com/android/server/locksettings/SyntheticPasswordManager.smali"
[ -f "$SMALI_FILE" ] || { LOGE "SyntheticPasswordManager.smali not found"; exit 1; }

# getWeaverHidlService() passes true to IWeaver.getService(Z); flip it to false.
# Anchor on the weaver getService invocation to avoid touching other constants.
if ! python3 - "$SMALI_FILE" << 'EOF'
import sys
p = sys.argv[1]
s = open(p).read()
old = '''    const/4 p0, 0x1

    :try_start_1
    invoke-static {p0}, Landroid/hardware/weaver/V1_0/IWeaver;->getService(Z)Landroid/hardware/weaver/V1_0/IWeaver;'''
new = '''    const/4 p0, 0x0

    :try_start_1
    invoke-static {p0}, Landroid/hardware/weaver/V1_0/IWeaver;->getService(Z)Landroid/hardware/weaver/V1_0/IWeaver;'''
if old in s:
    open(p, 'w').write(s.replace(old, new, 1))
    print("patched")
elif 'const/4 p0, 0x0\n\n    :try_start_1\n    invoke-static {p0}, Landroid/hardware/weaver/V1_0/IWeaver;->getService(Z)' in s:
    print("already-patched")
else:
    print("NOT-FOUND")
    sys.exit(1)
EOF
then
    LOGE "Weaver smali patch pattern not found (framework layout changed?)"
    exit 1
fi

EVAL "smali a \"$WEAVER_TMP/smali\" -o \"$WEAVER_TMP/patched.dex\"" || exit 1

# Rebuild services.jar with the patched dex (preserve entry order).
python3 - "$SERVICES_JAR" "$WEAVER_TMP/patched.dex" "$TARGET_DEX" "$WEAVER_TMP/services_new.jar" << 'EOF'
import sys, zipfile, shutil
src, patched, target, dst = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
zin = zipfile.ZipFile(src)
patched_data = open(patched, 'rb').read()
with zipfile.ZipFile(dst, 'w', zipfile.ZIP_STORED) as zout:
    for item in zin.infolist():
        data = zin.read(item.filename)
        if item.filename == target:
            data = patched_data
        zout.writestr(item, data)
EOF
[ -s "$WEAVER_TMP/services_new.jar" ] || { LOGE "services.jar rebuild failed"; exit 1; }

EVAL "cp -a \"$WEAVER_TMP/services_new.jar\" \"$SERVICES_JAR\""

LOG "- Weaver patch applied (getService(false))"
LOG_STEP_OUT
