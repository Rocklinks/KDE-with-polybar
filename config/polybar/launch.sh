#!/bin/bash

# Terminate already running Polybar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u "$UID" -x polybar > /dev/null; do sleep 1; done

# Run Polybar in the background and log output to ~/.config/polybar/polybar.log
mkdir -p ~/.config/polybar
polybar &> ~/.config/polybar/polybar.log &

# Wait a few seconds to ensure log is written
sleep 2

# Check if running under KDE (Plasma)
if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
  WINDOW_ID=$(grep -oP '(?<=window=)0x[0-9a-f]+' ~/.config/polybar/polybar.log)
   
  if [[ "$WINDOW_ID" =~ ^0x[0-9a-f]+$ ]]; then
    xkill -id "$WINDOW_ID"
  fi
fi
