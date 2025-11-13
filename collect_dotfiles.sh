#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"
MANIFEST="${REPO_ROOT}/dotfiles.manifest"

DRY_RUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run]

Collects configured dotfiles from this system into a timestamped snapshot.
Snapshots are stored under:
  ${REPO_ROOT}/backup/<timestamp>

Options:
  --dry-run   Show actions without copying or modifying files.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "${MANIFEST}" ]]; then
  echo "Manifest not found at ${MANIFEST}" >&2
  exit 1
fi

timestamp="$(date -Iseconds)"
snapshot_root="${REPO_ROOT}/backup/${timestamp}"

expand_path() {
  local path_template="$1"
  eval "printf '%s' \"${path_template}\""
}

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "Dry run: snapshot would be created at ${snapshot_root}"
else
  mkdir -p "${snapshot_root}"
fi

while IFS= read -r line || [[ -n "${line}" ]]; do
  [[ -z "${line}" || "${line}" =~ ^# ]] && continue

  rel_path="${line%%|*}"
  target_template="${line#*|}"

  if [[ -z "${rel_path}" || -z "${target_template}" ]]; then
    echo "Invalid manifest entry: ${line}" >&2
    continue
  fi

  src_path="$(expand_path "${target_template}")"
  dest_path="${snapshot_root}/${rel_path}"

  if [[ ! -e "${src_path}" ]]; then
    echo "Warning: source not found -> ${src_path}"
    continue
  fi

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "Would collect ${src_path} -> ${dest_path}"
    continue
  fi

  mkdir -p "$(dirname "${dest_path}")"

  if [[ -d "${src_path}" ]]; then
    rsync -a --delete "${src_path%/}/" "${dest_path%/}/"
  else
    cp -a "${src_path}" "${dest_path}"
  fi
done < "${MANIFEST}"

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "Dry run complete. No changes made."
else
  echo "Snapshot stored in ${snapshot_root}"
fi

