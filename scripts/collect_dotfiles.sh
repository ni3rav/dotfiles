#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MANIFEST="${REPO_ROOT}/dotfiles.manifest"

if [[ ! -f "${MANIFEST}" ]]; then
  echo "Manifest not found at ${MANIFEST}" >&2
  exit 1
fi

timestamp="$(date +"%Y%m%d-%H%M%S")"
backup_root="/timestemp/dotfiles-collect-${timestamp}"

mkdir -p "/timestemp"
mkdir -p "${backup_root}"

expand_path() {
  local path_template="$1"
  eval "printf '%s' \"${path_template}\""
}

while IFS= read -r line || [[ -n "${line}" ]]; do
  [[ -z "${line}" || "${line}" =~ ^# ]] && continue

  rel_path="${line%%|*}"
  target_template="${line#*|}"

  if [[ -z "${rel_path}" || -z "${target_template}" ]]; then
    echo "Invalid manifest entry: ${line}" >&2
    continue
  fi

  src_path="$(expand_path "${target_template}")"
  dest_path="${REPO_ROOT}/${rel_path}"

  if [[ ! -e "${src_path}" ]]; then
    echo "Warning: source not found -> ${src_path}"
    continue
  fi

  if [[ -d "${src_path}" ]]; then
    mkdir -p "$(dirname "${dest_path}")"
    if [[ -d "${dest_path}" ]]; then
      mkdir -p "${backup_root}/$(dirname "${rel_path}")"
      rsync -a "${dest_path%/}/" "${backup_root}/${rel_path%/}/"
    fi
    rsync -a --delete "${src_path%/}/" "${dest_path%/}/"
  else
    mkdir -p "$(dirname "${dest_path}")"
    if [[ -e "${dest_path}" ]]; then
      mkdir -p "${backup_root}/$(dirname "${rel_path}")"
      cp -a "${dest_path}" "${backup_root}/${rel_path}"
    fi
    cp -a "${src_path}" "${dest_path}"
  fi
done < "${MANIFEST}"

echo "Dotfiles collected. Backups (if any) stored in ${backup_root}"

