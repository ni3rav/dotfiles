#!/usr/bin/env bash

## Emoji picker. Copies the choice to the clipboard.

if ! command -v rofimoji >/dev/null; then
	echo "rofimoji is not installed. Install it with: pip3 install --user rofimoji" >&2
	exit 1
fi

exec rofimoji \
	--action copy \
	--selector rofi \
	--clipboarder wl-copy \
	--skin-tone ask \
	--selector-args "-theme ${HOME}/.config/rofi/launchers/type-1/style-7.rasi -i"
