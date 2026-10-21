# The 5.4 Samsung kernel's runtime SELinux policy patching crashes on this
# device, so the ksu domain and the rules from the kernel's
# apply_kernelsu_rules() are pre-declared in the vendor policy instead.

CIL="$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"
[ -f "$CIL" ] || { LOGE "vendor_sepolicy.cil not found"; exit 1; }

if grep -q "^(type ksu)$" "$CIL"; then
    LOG "- ksu SELinux rules already present, skipping"
    return 0 2>/dev/null || exit 0
fi

LOG "- Adding ksu SELinux domain rules"
cat >> "$CIL" <<'CIL_EOF'

; KernelSU (non-GKI): pre-declared ksu domain + allow rules.
(type ksu)
(typeattributeset domain (ksu))
(typepermissive ksu)
(typeattributeset mlstrustedsubject (ksu))
(typeattributeset netdomain (ksu))
(typeattributeset bluetoothdomain (ksu))
(type ksu_file)
(typeattributeset file_type (ksu_file))
(typeattributeset mlstrustedobject (ksu_file))
(allow domain ksu_file (dir (ioctl read write create getattr setattr lock search add_name remove_name reparent rmdir open audit_access)))
(allow domain ksu_file (file (ioctl read write create getattr setattr lock append map unlink link rename execute open audit_access)))
(allow init ksu (process (transition)))
(allow init adb_data_file (dir (ioctl read write create getattr setattr lock search add_name remove_name reparent rmdir open audit_access)))
(allow init adb_data_file (file (ioctl read write create getattr setattr lock append map unlink link rename execute open audit_access)))
(allow servicemanager ksu (dir (search read)))
(allow servicemanager ksu (file (open read)))
(allow servicemanager ksu (process (getattr)))
(allow logd ksu (dir (search)))
(allow logd ksu (file (read open getattr)))
(allow hwservicemanager ksu (dir (search)))
(allow hwservicemanager ksu (file (read open)))
(allow hwservicemanager ksu (process (getattr)))
(allow domain ksu (process (sigchld)))
(allow domain ksu (fd (use)))
(allow domain ksu (fifo_file (read write open getattr)))
(allow domain ksu (binder (call transfer impersonate set_context_mgr)))
(allow domain ksu (unix_stream_socket (read write connectto getopt getattr)))
(allow system_server ksu (process (getpgid sigkill)))
CIL_EOF
LOG "- ksu SELinux rules added"
