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
