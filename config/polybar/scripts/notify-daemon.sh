#!/bin/bash
# Clear the /tmp/rofi_notification_daemon file
rm -f /tmp/rofi_notification_daemon

# Start the rofication daemon
python3 ~/.config/polybar/scripts/notification/rofication-daemon.py

