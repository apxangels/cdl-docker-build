#!/bin/bash
set -e

APP_DIR="/cyberdrop-dl/AppData"

# Redirect XDG paths into a single volume for easy persistence
export XDG_CONFIG_HOME="${APP_DIR}/.config"
export XDG_DATA_HOME="${APP_DIR}/.local/share"
export XDG_CACHE_HOME="${APP_DIR}/.cache"
export XDG_STATE_HOME="${APP_DIR}/.local/state"

# Ensure directories exist and belong to the runtime user
mkdir -p "${XDG_CONFIG_HOME}/cyberdrop-dl"
mkdir -p "${XDG_DATA_HOME}/cyberdrop-dl"
mkdir -p "${XDG_CACHE_HOME}/cyberdrop-dl"
mkdir -p "${XDG_STATE_HOME}/cyberdrop-dl/logs"

# Fix ownership for volume mounts that come in as root
chown -R abc:abc "${APP_DIR}" 2>/dev/null || true

# Ensure cache.json is a valid JSON dict (empty or corrupted files crash v10)
CACHE_FILE="${XDG_CACHE_HOME}/cyberdrop-dl/cache.json"
if ! python3 -c "import json,sys; data=json.load(open('${CACHE_FILE}')); sys.exit(0 if type(data) is dict else 1)" 2>/dev/null; then
    echo '{}' > "${CACHE_FILE}"
    chown abc:abc "${CACHE_FILE}" 2>/dev/null || true
fi

CONFIG_FILE="${XDG_CONFIG_HOME}/cyberdrop-dl/config.yaml"

if [ ! -f "${CONFIG_FILE}" ]; then
    echo "No config found. Creating default config..." >&2
    COLUMNS=999 gosu abc:abc cyberdrop-dl config new > "${CONFIG_FILE}"
fi

# Ensure download_folder points to the container path exposed for volume mounting
DOWNLOAD_FOLDER="${CDL_DOWNLOAD_FOLDER:-/cyberdrop-dl/downloads}"
sed -i "s|^download_folder: .*|download_folder: ${DOWNLOAD_FOLDER}|" "${CONFIG_FILE}"

args=("$@")

# Auto-append --input-file for CLI 'download' when not explicitly provided
# and a URLs.txt exists at the conventional location.
if [[ " ${args[*]} " == *" download "* ]] \
   && [[ " ${args[*]} " != *" --input-file "* ]] \
   && [[ " ${args[*]} " != *" -i "* ]]; then
    if [ -f "/cyberdrop-dl/URLs.txt" ]; then
        args+=("--input-file" "/cyberdrop-dl/URLs.txt")
    fi
fi

exec gosu abc:abc "${args[@]}"
