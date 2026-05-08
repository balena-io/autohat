#!/usr/bin/env bash

set -euo pipefail
set -x

function cleanup() {
  umount "${tmpmnt:-}" || true
  rm -rf "${tmpfdisk:-}" "${tmpmnt:-}"
}
trap cleanup EXIT

output_dir="${1:?usage: $0 <output_dir> <image>}"
image="${2:?usage: $0 <output_dir> <image>}"
[[ -d ${output_dir} ]] || {
  echo "output dir not found: ${output_dir}" >&2
  exit 64
}
[[ -r ${image} ]] || {
  echo "image not readable: ${image}" >&2
  exit 64
}

tmpfdisk="$(mktemp)"
fdisk -lu "${image}" >"${tmpfdisk}"
cat <"${tmpfdisk}"

uname -a
tmpmnt="$(mktemp -d)"
extracted=0

while IFS= read -r offset; do
  # look for installer migration log in FAT parts.
  mntopts="ro,loop,offset=$((offset * 512))"
  mount -o "${mntopts}" "${image}" "${tmpmnt}" || continue

  # inspect FAT parts.
  find "${tmpmnt}" -type f

  # find balena image flasher (installer) initramfs mode log (should be in the boot part.)
  # balena-os/meta-balena: docs/initramfs.md?plain=1#L24
  # ..                     meta-balena-common/recipes-support/resin-init/resin-init-flasher/resin-init-flasher#L561
  find "${tmpmnt}" -type f -name 'migration_*' -print0 |
    xargs -0r cat >"${output_dir}/${offset}-flasher.log"

  if test -s "${output_dir}/${offset}-flasher.log"; then
    extracted=$((extracted + 1))
  else
    rm -f "${output_dir}/${offset}-flasher.log"
  fi

  umount "${tmpmnt}"
done < <(grep -E '(EFI|FAT16)' "${tmpfdisk}" | sed 's/*//g' | awk '{print $2}')

while IFS= read -r offset; do
  # look for system.journal in Linux parts.
  mounted=0
  for mntopt in ro ro,norecovery ro,rescue=nologreplay; do
    # https://btrfs.readthedocs.io/en/latest/Kernel-by-version.html#jul-2024
    mntopts="${mntopt},loop,offset=$((offset * 512))"
    mount -o "${mntopts}" "${image}" "${tmpmnt}" && {
      mounted=1
      break
    }
  done
  ((mounted)) || continue

  # find all systemd-journald logs
  journal_args=()
  while IFS= read -r -d '' j; do
    journal_args+=(--file "$j")
  done < <(find "${tmpmnt}" -type f -name system.journal -print0)
  ((${#journal_args[@]} > 0)) &&
    journalctl --no-pager "${journal_args[@]}" >"${output_dir}/${offset}-system.log"

  if test -s "${output_dir}/${offset}-system.log"; then
    extracted=$((extracted + 1))
  else
    rm -f "${output_dir}/${offset}-system.log"
  fi

  umount "${tmpmnt}"
done < <(grep -E 'Linux( filesystem)?$' "${tmpfdisk}" | awk '{print $2}')

if ((extracted == 0)); then
  echo "ERROR: no logs extracted from ${image}" >&2
  exit 2
else
  find "${output_dir}" -type f
fi
