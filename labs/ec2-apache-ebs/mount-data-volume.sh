#!/usr/bin/env bash
# Run on the lab's AL2023 Nitro instance; never guess an NVMe device name.
set -euo pipefail

prepare_data_filesystem() {
  local device=$1 format=${2:-} types mounts filesystem probe_status signatures
  # Empty output after a failed read must never mean an unmounted/blank device.
  if ! types=$(lsblk -nr -o TYPE -- "$device" 2>&1); then
    echo 'Cannot inspect device topology; refusing to format or mount.' >&2
    return 1
  fi
  [[ $types == disk ]] || { echo 'Refusing a partitioned or non-disk device.' >&2; return 1; }
  if ! mounts=$(lsblk -nr -o MOUNTPOINTS -- "$device" 2>&1); then
    echo 'Cannot inspect existing mounts; refusing to format or mount.' >&2
    return 1
  fi
  [[ -z ${mounts//[[:space:]]/} ]] || {
    echo 'Device is already mounted; inspect it rather than formatting.' >&2
    return 1
  }
  # blkid -p: 0 identified, 2 not identified, 4 error, 8 ambiguous.
  # Status 2 is NOT proof of a blank disk. Capture diagnostics as well.
  if filesystem=$(blkid -p -s TYPE -o value -- "$device" 2>&1); then
    [[ $filesystem == xfs ]] || {
      echo 'Existing non-XFS or unrecognized content found; refusing to modify it.' >&2
      return 1
    }
    return 0
  else
    probe_status=$?
  fi
  if [[ $probe_status -ne 2 || -n $filesystem ]]; then
    echo 'Filesystem probe failed or was ambiguous; refusing to format.' >&2
    return 1
  fi
  # Independently require a successful, empty signature read. Never erase signatures.
  if ! signatures=$(wipefs --noheadings --output TYPE -- "$device" 2>&1); then
    echo 'Signature probe failed; refusing to format.' >&2
    return 1
  fi
  [[ -z $signatures ]] || { echo 'Existing signatures or probe diagnostics found; refusing to format.' >&2; return 1; }
  [[ $format == '--format-new' ]] || {
    echo 'No recognized signatures: use --format-new only for the new disposable lab volume.' >&2
    return 2
  }
  # Do not use mkfs -f: retain its own existing-filesystem guard.
  mkfs.xfs "$device" || return 1
}

main() {
  if [[ $# -lt 1 || $# -gt 2 || ! $1 =~ ^vol-[0-9a-f]+$ || ${2:-} != "" && ${2:-} != "--format-new" ]]; then
    echo "Usage: sudo bash $0 vol-0123456789abcdef0 [--format-new]" >&2
    return 2
  fi
  [[ $EUID -eq 0 ]] || { echo 'Run as root on the lab instance.' >&2; return 2; }
  local serial=${1//-/} inventory device uuid
  inventory=$(lsblk -dn -o PATH,SERIAL) || { echo 'Cannot enumerate block devices.' >&2; return 1; }
  device=$(awk -v expected="$serial" '$2 == expected {print $1}' <<< "$inventory")
  [[ -n $device && $device != *$'\n'* && -b $device ]] || {
    echo 'Expected exactly one block device matching the supplied EBS volume ID.' >&2
    return 1
  }
  prepare_data_filesystem "$device" "${2:-}" || return $?
  mkdir -p /mnt/lab-data
  mountpoint -q /mnt/lab-data && { echo 'Mountpoint already in use.' >&2; return 1; }
  uuid=$(blkid -s UUID -o value "$device")
  mount "UUID=$uuid" /mnt/lab-data
  if ! grep -Fq "UUID=$uuid " /etc/fstab; then
    printf 'UUID=%s /mnt/lab-data xfs defaults,nofail 0 2\n' "$uuid" >> /etc/fstab
  fi
  printf 'Mounted %s at /mnt/lab-data. Verify with findmnt and df -h.\n' "$1"
}

# Sourcing defines the testable probe boundary; it never runs main.
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
