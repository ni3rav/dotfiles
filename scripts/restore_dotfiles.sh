#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MANIFEST="${REPO_ROOT}/dotfiles.manifest"

DRY_RUN=false
timestamp="$(date +"%Y%m%d-%H%M%S")"
BACKUP_ROOT="/timestemp/dotfiles-restore-${timestamp}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run]

Copies dotfiles from the repository into their target locations.
A backup copy of any overwritten file or directory is stored under:
  ${BACKUP_ROOT}

Options:
  --dry-run   Show actions without applying changes.
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

if [[ "${DRY_RUN}" == "false" ]]; then
  mkdir -p "/timestemp"
  mkdir -p "${BACKUP_ROOT}"
fi

expand_path() {
  local path_template="$1"
  eval "printf '%s' \"${path_template}\""
}

do_backup() {
  local target="$1"
  local rel="$2"

  mkdir -p "${BACKUP_ROOT}/$(dirname "${rel}")"
  if [[ -d "${target}" ]]; then
    rsync -a "${target%/}/" "${BACKUP_ROOT}/${rel%/}/"
  else
    cp -a "${target}" "${BACKUP_ROOT}/${rel}"
  fi
}

actions=()

while IFS= read -r line || [[ -n "${line}" ]]; do
  [[ -z "${line}" || "${line}" =~ ^# ]] && continue

  rel_path="${line%%|*}"
  target_template="${line#*|}"

  if [[ -z "${rel_path}" || -z "${target_template}" ]]; then
    echo "Invalid manifest entry: ${line}" >&2
    continue
  fi

  source_path="${REPO_ROOT}/${rel_path}"
  target_path="$(expand_path "${target_template}")"

  if [[ ! -e "${source_path}" ]]; then
    echo "Warning: missing source -> ${source_path}"
    continue
  fi

  actions+=("Install ${source_path} -> ${target_path}")

  if [[ "${DRY_RUN}" == "true" ]]; then
    continue
  fi

  mkdir -p "$(dirname "${target_path}")"

  if [[ -e "${target_path}" ]]; then
    do_backup "${target_path}" "${rel_path}"
  fi

  if [[ -d "${source_path}" ]]; then
    rsync -a --delete "${source_path%/}/" "${target_path%/}/"
  else
    cp -a "${source_path}" "${target_path}"
  fi
done < "${MANIFEST}"

if (( ${#actions[@]} > 0 )); then
  printf '%s\n' "${actions[@]}"
fi

if [[ "${DRY_RUN}" == "false" ]]; then
  echo "Backups stored in: ${BACKUP_ROOT}"
fi

