#!/usr/bin/env bash

theme="$HOME/.config/rofi/config.rasi"
title=$(uptime -p 2>/dev/null || echo "Power")
title="${title^}"

menu() {
	local lines=$1
	local message=$2
	shift 2
	local -a extra=()
	if [[ -n "$message" ]]; then
		extra=(
			-mesg "$message"
			-theme-str 'mainbox { children: [ "inputbar", "message", "listview" ]; }'
			-theme-str 'message { enabled: true; border: 0; padding: 2px 4px 0; background-color: transparent; text-color: @foreground; }'
		)
	fi
	printf '%s\n' "$@" | rofi -dmenu -no-custom -no-show-icons \
		-p "$title" \
		-theme "$theme" \
		-theme-str "listview { lines: ${lines}; }" \
		-theme-str 'inputbar { children: [ "prompt" ]; }' \
		-theme-str 'prompt { enabled: true; expand: true; horizontal-align: 0.5; background-color: transparent; text-color: @foreground; }' \
		-theme-str 'element-icon { enabled: false; }' \
		-theme-str 'element-text { background-color: transparent; text-color: @foreground; }' \
		"${extra[@]}"
}

choice=$(menu 5 "" Lock Suspend Logout Reboot Shutdown)
case "$choice" in
	Lock)
		qdbus-qt6 org.freedesktop.ScreenSaver /ScreenSaver Lock \
			|| loginctl lock-session
		;;
	Suspend | Logout | Reboot | Shutdown)
		case "$choice" in
			Suspend) question="Suspend now?" ;;
			Logout) question="Log out now?" ;;
			Reboot) question="Reboot now?" ;;
			Shutdown) question="Shut down now?" ;;
		esac
		confirm=$(menu 2 "$question" Yes No)
		[[ "$confirm" == Yes ]] || exit 0
		case "$choice" in
			Suspend)
				amixer set Master mute >/dev/null 2>&1 || true
				systemctl suspend
				;;
			Logout)
				qdbus-qt6 org.kde.Shutdown /Shutdown logout
				;;
			Reboot)
				systemctl reboot
				;;
			Shutdown)
				shutdown -h now
				;;
		esac
		;;
esac
