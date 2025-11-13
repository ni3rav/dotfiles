#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"
MANIFEST="${REPO_ROOT}/dotfiles.manifest"

DRY_RUN=false
SNAPSHOT=""
INTERACTIVE=false
SKIP_BACKUP=false
timestamp="$(date -Iseconds)"
BACKUP_ROOT="${REPO_ROOT}/backup/restore-${timestamp}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Copies dotfiles from a collected snapshot into their target locations.
Snapshots must exist under:
  ${REPO_ROOT}/backup/<timestamp>
Backups of overwritten files or directories are stored under:
  ${BACKUP_ROOT}

Options:
  --dry-run          Show actions without applying changes.
  --snapshot <path>  Timestamp (folder name) or absolute path to use as source snapshot.
  --interactive      Interactive mode: select snapshot from available backups.
  --skip-backup      Skip creating backup of current config (dangerous!).
  -h, --help         Show this help message.
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
    --interactive)
      INTERACTIVE=true
      shift
      ;;
    --skip-backup)
      SKIP_BACKUP=true
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

select_snapshot_interactive() {
  local base="${REPO_ROOT}/backup"

  if [[ ! -d "${base}" ]]; then
    echo "No backup snapshots found under ${base}" >&2
    exit 1
  fi

  mapfile -t snapshots < <(find "${base}" -mindepth 1 -maxdepth 1 -type d -name "20*" | sort -r)
  if [[ ${#snapshots[@]} -eq 0 ]]; then
    echo "No backup snapshots found under ${base}" >&2
    exit 1
  fi

  echo "Available snapshots:" >&2
  echo >&2
  for i in "${!snapshots[@]}"; do
    snapshot_name=$(basename "${snapshots[$i]}")
    echo "$((i+1)). ${snapshot_name}" >&2
  done
  echo >&2
  echo -n "Select snapshot (1-${#snapshots[@]}, or 'q' to quit): " >&2
  read -r choice

  if [[ "${choice}" == "q" || "${choice}" == "Q" ]]; then
    echo "Operation cancelled." >&2
    printf '%s' "__CANCELLED__"
    return
  fi

  if ! [[ "${choice}" =~ ^[0-9]+$ ]] || [[ "${choice}" -lt 1 ]] || [[ "${choice}" -gt "${#snapshots[@]}" ]]; then
    echo "Invalid selection. Please try again." >&2
    exit 1
  fi

  printf '%s' "${snapshots[$((choice-1))]}"
}

resolve_snapshot() {
  local requested="$1"
  local base="${REPO_ROOT}/backup"

  if [[ "${INTERACTIVE}" == "true" ]]; then
    select_snapshot_interactive
    return
  fi

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

# Check if user cancelled interactive selection
if [[ "${SNAPSHOT_ROOT}" == "__CANCELLED__" ]]; then
  exit 0
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

# Confirmation warning
if [[ "${DRY_RUN}" == "false" ]]; then
  echo "  WARNING: This will overwrite your existing configuration files!"
  echo
  echo "Snapshot to restore: $(basename "${SNAPSHOT_ROOT}")"
  echo "Backup location: ${BACKUP_ROOT}"
  echo
  echo "The following actions will be performed:"
  echo "- Restore dotfiles from snapshot to their target locations"
  if [[ "${SKIP_BACKUP}" == "false" ]]; then
    echo "- Create backup of current config in: ${BACKUP_ROOT}"
  else
    echo "-   SKIP creating backup of current config (dangerous!)"
  fi
  echo
  read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
  fi
fi

actions=()

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "Dry run: would restore from ${SNAPSHOT_ROOT}"
else
  if [[ "${SKIP_BACKUP}" == "false" ]]; then
    mkdir -p "${BACKUP_ROOT}"
  fi
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

  if [[ -e "${target_path}" && "${SKIP_BACKUP}" == "false" ]]; then
    do_backup "${target_path}" "${rel_path}"
  fi

  if [[ -d "${source_path}" ]]; then
    rsync -a --delete "${source_path%/}/" "${target_path%/}/"
  else
    cp -a "${source_path}" "${target_path}"
  fi
done < "${MANIFEST}"

printf '%s\n' "${actions[@]}"

if [[ "${DRY_RUN}" == "false" && "${SKIP_BACKUP}" == "false" ]]; then
  echo "Backups stored in: ${BACKUP_ROOT}"
elif [[ "${DRY_RUN}" == "false" && "${SKIP_BACKUP}" == "true" ]]; then
  echo "  No backup created (skip-backup was enabled)"
fi

