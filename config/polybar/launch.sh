#!/bin/bash

# Terminate already running Polybar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar > /dev/null; do sleep 1; done

# Run Polybar in the background and log output
polybar &> polybar.log &

# Wait for a few seconds to ensure the log is written
sleep 2

# Extract the window ID from the log file
WINDOW_ID=$(grep -oP '(?<=window=)0x[0-9a-f]+' polybar.log)

# Check if a valid window ID was found
if [[ "$WINDOW_ID" =~ ^0x[0-9a-f]+$ ]]; then
  echo "Found systray window ID: $WINDOW_ID"
  
  # Use xkill to terminate the window
  xkill -id "$WINDOW_ID"
  echo "Systray with ID $WINDOW_ID killed."
else
  echo "No systray window found or already managed by another application."
fi

echo "Polybar launched..."
