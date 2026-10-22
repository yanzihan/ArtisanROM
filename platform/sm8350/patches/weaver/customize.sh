# p3q-specific framework patch: the S24U framework's SyntheticPasswordManager
# calls IWeaver.getService(true), which BLOCKS forever when the device has no
# weaver HAL (p3q's TEE reports "weaver unsupported"). system_server then hangs
# in checkWeaverStatus() at boot, the watchdog kills it, and the boot loops on
# the animation. Patch the call to getService(false) so it returns null fast
# and the existing "weaver NOT available" path is taken.

LOG_STEP_IN "- Patching SyntheticPasswordManager weaver lookup"

# Edit the apktool cache instead of doing a baksmali/smali round-trip on the
# whole jar: BUILD_APKS rebuilds services.jar from this cache afterwards, and
# the cache is shared with the other services.jar patches.
DECODE_APK "system" "system/framework/services.jar" || exit 1

SMALI_FILE="$(find "$APKTOOL_DIR/system/framework/services.jar" -type f \
    -path "*/com/android/server/locksettings/SyntheticPasswordManager.smali" -print -quit)"
[ -n "$SMALI_FILE" ] || { LOGE "SyntheticPasswordManager.smali not found"; exit 1; }

# getWeaverHidlService() passes true to IWeaver.getService(Z); flip it to false.
# Match the invocation itself so other const/4 p0, 0x1 sites are untouched, and
# accept any try_start label (Android 17 moved it to :try_start_0).
if ! python3 - "$SMALI_FILE" << 'EOF'
import re, sys
p = sys.argv[1]
s = open(p).read()
pat = re.compile(r"    const/4 p0, 0x1\n\n    :try_start_\d+\n    invoke-static \{p0\}, Landroid/hardware/weaver/V1_0/IWeaver;->getService\(Z\)")
already = re.compile(r"    const/4 p0, 0x0\n\n    :try_start_\d+\n    invoke-static \{p0\}, Landroid/hardware/weaver/V1_0/IWeaver;->getService\(Z\)")
if pat.search(s):
    s = pat.sub(lambda m: m.group(0).replace("const/4 p0, 0x1", "const/4 p0, 0x0", 1), s, count=1)
    open(p, "w").write(s)
    print("patched")
elif already.search(s):
    print("already-patched")
else:
    print("NOT-FOUND")
    sys.exit(1)
EOF
then
    LOGE "Weaver smali patch pattern not found (framework layout changed?)"
    exit 1
fi

LOG "- Weaver patch applied (getService(false))"
LOG_STEP_OUT
