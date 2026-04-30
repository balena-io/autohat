#!/usr/bin/env bash

set -euo pipefail
set -x

function cleanup() {
  rm -rf "${tmpfdisk}" "${tmpmnt}"
}
trap cleanup EXIT

tmpfdisk="$(mktemp)"
fdisk -lu "${2}" >"${tmpfdisk}"
cat <"${tmpfdisk}"

uname -a
tmpmnt="$(mktemp -d)"

grep -E '(EFI|FAT16)' "${tmpfdisk}" | sed 's/*//g' | awk '{print $2}' |
  while IFS= read -r offset; do
    # look for installer migration log in FAT parts.
    mntopts="ro,loop,offset=$((offset * 512))"
    mount -o "${mntopts}" "${2}" "${tmpmnt}" || continue

    # inspect FAT parts.
    find "${tmpmnt}" -type f

    # find balena image flasher (installer) initramfs mode log (should be in the boot part.)
    # balena-os/meta-balena: docs/initramfs.md?plain=1#L24
    # ..                     meta-balena-common/recipes-support/resin-init/resin-init-flasher/resin-init-flasher#L561
    find "${tmpmnt}" -type f -name 'migration_*' -print0 |
      xargs -0r cat >"${1}/${offset}-flasher.log"
    test -s "${1}/${offset}-flasher.log" || rm "${1}/${offset}-flasher.log"

    umount "${tmpmnt}"
  done

grep Linux "${tmpfdisk}" | awk '{print $2}' |
  while IFS= read -r offset; do
    # look for system.journal in Linux parts.
    for mntopt in ro ro,norecovery ro,rescue=nologreplay; do
      # https://btrfs.readthedocs.io/en/latest/Kernel-by-version.html#jul-2024
      mntopts="${mntopt},loop,offset=$((offset * 512))"
      mount -o "${mntopts}" "${2}" "${tmpmnt}" && break # if mntopts accepted
    done
    # shellcheck disable=SC2181
    [[ $? -eq 0 ]] || continue # continue to trying the next part.

    # find systemd-journald logs
    find "${tmpmnt}" -type f -name system.journal -print0 |
      xargs -0r journalctl --no-pager --file >"${1}/${offset}-system.log"
    test -s "${1}/${offset}-system.log" || rm "${1}/${offset}-system.log"

    umount "${tmpmnt}"
  done

find "${1}" -type f
