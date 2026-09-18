#!/usr/bin/env bash
# No device is accessed: every command used by prepare_data_filesystem is a fake.
set -euo pipefail
# Some Windows bundles expose GNU Bash as sh.exe, which starts in POSIX mode.
# This is a Bash test (including the dotted native-command fake below).
set +o posix
repo_root=$(cd "${BASH_SOURCE[0]%/*}/.." && pwd)
# shellcheck source=../labs/ec2-apache-ebs/mount-data-volume.sh
source "$repo_root/labs/ec2-apache-ebs/mount-data-volume.sh"

lsblk() {
  if [[ $* == *MOUNTPOINTS* ]]; then
    printf '%s' "$mount_output"
    return "$mount_status"
  fi
  printf '%s' "$type_output"
  return "$type_status"
}
blkid() {
  printf '%s' "$blkid_output"
  printf '%s' "$blkid_error" >&2
  return "$blkid_status"
}
wipefs() {
  printf '%s' "$wipefs_output"
  printf '%s' "$wipefs_error" >&2
  return "$wipefs_status"
}
mkfs.xfs() {
  [[ $# -eq 1 && $1 == '/mock/device' ]] || { echo 'Unexpected formatting target.' >&2; return 99; }
  ((format_calls += 1))
  return "$format_status"
}

passed=0
run_case() {
  local name=$1 expected_status=$2 expected_formats=$3 format_flag=$4
  shift 4
  type_output=disk type_status=0 mount_output='' mount_status=0
  blkid_output='' blkid_error='' blkid_status=2
  wipefs_output='' wipefs_error='' wipefs_status=0
  format_calls=0 format_status=0
  local setting status
  # Fixed test fixture names/values only; never eval.
  for setting in "$@"; do
    printf -v "${setting%%=*}" '%s' "${setting#*=}"
  done
  if prepare_data_filesystem '/mock/device' "$format_flag" 2>/dev/null; then
    status=0
  else
    status=$?
  fi
  if [[ $status -ne $expected_status || $format_calls -ne $expected_formats ]]; then
    printf 'FAIL %s: status=%s formats=%s\n' "$name" "$status" "$format_calls" >&2
    return 1
  fi
  ((passed += 1))
  printf 'PASS %s\n' "$name"
}

run_case 'verified no-signature device requires explicit format' 0 1 --format-new
run_case 'no format flag leaves unsigned device untouched' 2 0 ''
run_case 'existing XFS accepted without formatting' 0 0 --format-new blkid_status=0 blkid_output=xfs
run_case 'existing ext4 rejected' 1 0 --format-new blkid_status=0 blkid_output=ext4
run_case 'successful but empty blkid is ambiguous' 1 0 --format-new blkid_status=0
run_case 'blkid error cannot reach formatter' 1 0 --format-new blkid_status=4
run_case 'blkid ambiguous signatures cannot reach formatter' 1 0 --format-new blkid_status=8
run_case 'unknown blkid failure cannot reach formatter' 1 0 --format-new blkid_status=126
run_case 'status 2 with partial output rejected' 1 0 --format-new blkid_output=xfs
run_case 'status 2 with diagnostics rejected' 1 0 --format-new 'blkid_error=read error'
run_case 'wipefs failure cannot reach formatter' 1 0 --format-new wipefs_status=1
run_case 'wipefs failed with partial output rejected' 1 0 --format-new wipefs_status=1 wipefs_output=xfs
run_case 'wipefs reports existing signature' 1 0 --format-new wipefs_output=gpt
run_case 'wipefs warning despite success rejected' 1 0 --format-new 'wipefs_error=warning'
run_case 'topology read failure rejected' 1 0 --format-new type_status=1
run_case 'mounted-state read failure rejected' 1 0 --format-new mount_status=1
run_case 'mounted device rejected' 1 0 --format-new mount_output=/
run_case 'partitioned device rejected' 1 0 --format-new $'type_output=disk\npart'
run_case 'mkfs failure propagated' 1 1 --format-new format_status=1
printf '%s mocked filesystem cases passed; no real devices or formatters were used.\n' "$passed"
