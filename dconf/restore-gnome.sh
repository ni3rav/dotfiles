#!/bin/bash

set -e

DCONF_FILE="$(dirname "$0")/gnome-input-workspaces.dconf"

echo "Restoring GNOME keybindings and workspace settings..."

if [ ! -f "$DCONF_FILE" ]; then
    echo "Backup file not found: $DCONF_FILE"
    exit 1
fi

echo "Disabling dynamic workspaces..."
gsettings set org.gnome.mutter dynamic-workspaces false

echo "Loading dconf settings..."
dconf load / < "$DCONF_FILE"

echo "Restore complete."
echo "Please log out and log back in."

