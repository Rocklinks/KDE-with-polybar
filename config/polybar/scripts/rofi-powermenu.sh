#!/usr/bin/env bash

# Import Current Theme
RASI="$cd ~/.config/polybar/rofi/powermenu.rasi"

# Theme Elements
prompt="`hostname` (`echo $DESKTOP_SESSION`)"
mesg="Uptime : `uptime -p | sed -e 's/up //g'`"

# Options
layout=`cat ${RASI} | grep 'USE_ICON' | cut -d'=' -f2`
if [[ "$layout" == 'NO' ]]; then
	option_1=" Lock"
	option_2=" Logout"
	option_3=" Suspend"
	option_5=" Reboot"
	option_6=" Shutdown"
else
	option_1=""
	option_2=""
	option_3=""
	option_5=""
	option_6=""
fi

rofi_cmd() {
	rofi -dmenu \
		-p "$prompt" \
        -kb-cancel Escape \
		-mesg "$mesg" \
		-markup-rows \
        -hover-select \
        -me-select-entry '' \
        -me-accept-entry MousePrimary \
		-theme ${RASI}
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$option_1\n$option_2\n$option_3\n$option_5\n$option_6" | rofi_cmd
}

# Detect session (lowercase for easier matching)
session="${XDG_CURRENT_DESKTOP,,}"

chosen="$(run_rofi)"
case "$chosen" in
    "$option_1")
        if [[ "$session" == *xfce* ]]; then
            xflock4
        elif [[ "$session" == *cinnamon* ]]; then
            cinnamon-screensaver-command --lock
        elif [[ "$session" == *plasma* ]]; then
            # KDE Plasma 6
            qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock
        elif [[ "$session" == *gnome* ]]; then
            # GNOME
            gnome-screensaver-command -l 2>/dev/null || loginctl lock-session
        fi
        ;;
    "$option_2")
        if [[ "$session" == *xfce* ]]; then
            xfce4-session-logout --logout
        elif [[ "$session" == *cinnamon* ]]; then
            cinnamon-session-quit --logout --no-prompt
        elif [[ "$session" == *plasma* ]]; then
            # KDE Plasma 6
            qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
        elif [[ "$session" == *gnome* ]]; then
            # GNOME
            gnome-session-quit --logout --no-prompt
        fi
        ;;
    "$option_3")
        systemctl suspend
        ;;
    "$option_5")
        systemctl reboot
        ;;
    "$option_6")
        systemctl poweroff
        ;;
esac
