#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"
MANIFEST="${REPO_ROOT}/dotfiles.manifest"

DRY_RUN=false
SNAPSHOT=""
timestamp="$(date -Iseconds)"
BACKUP_ROOT="${REPO_ROOT}/backup/restore-${timestamp}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--snapshot <timestamp|path>]

Copies dotfiles from a collected snapshot into their target locations.
Snapshots must exist under:
  ${REPO_ROOT}/backup/<timestamp>
Backups of overwritten files or directories are stored under:
  ${BACKUP_ROOT}

Options:
  --dry-run   Show actions without applying changes.
  --snapshot  Timestamp (folder name) or absolute path to use as source snapshot.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --snapshot)
      SNAPSHOT="$2"
      shift 2
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

resolve_snapshot() {
  local requested="$1"
  local base="${REPO_ROOT}/backup"

  if [[ -n "${requested}" ]]; then
    if [[ -d "${requested}" ]]; then
      printf '%s' "${requested}"
      return
    fi

    if [[ -d "${base}/${requested}" ]]; then
      printf '%s' "${base}/${requested}"
      return
    fi

    echo "Snapshot not found: ${requested}" >&2
    exit 1
  fi

  if [[ ! -d "${base}" ]]; then
    echo "No backup snapshots found under ${base}" >&2
    exit 1
  fi

  mapfile -t snapshots < <(find "${base}" -mindepth 1 -maxdepth 1 -type d | sort)
  if [[ ${#snapshots[@]} -eq 0 ]]; then
    echo "No backup snapshots found under ${base}" >&2
    exit 1
  fi

  printf '%s' "${snapshots[-1]}"
}

SNAPSHOT_ROOT="$(resolve_snapshot "${SNAPSHOT}")"

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

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "Dry run: would restore from ${SNAPSHOT_ROOT}"
else
  mkdir -p "${BACKUP_ROOT}"
  echo "Restoring from snapshot: ${SNAPSHOT_ROOT}"
fi

while IFS= read -r line || [[ -n "${line}" ]]; do
  [[ -z "${line}" || "${line}" =~ ^# ]] && continue

  rel_path="${line%%|*}"
  target_template="${line#*|}"

  if [[ -z "${rel_path}" || -z "${target_template}" ]]; then
    echo "Invalid manifest entry: ${line}" >&2
    continue
  fi

  source_path="${SNAPSHOT_ROOT}/${rel_path}"
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

printf '%s\n' "${actions[@]}"

if [[ "${DRY_RUN}" == "false" ]]; then
  echo "Backups stored in: ${BACKUP_ROOT}"
fi

