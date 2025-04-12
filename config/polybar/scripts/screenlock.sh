#!/bin/bash

# Set idle time to 15 minutes
xset s 900 900        # First: screen blank, Second: screen off
xset +dpms            # Enable DPMS (Display Power Management)
xset dpms 0 0 900     # Turn off screen after 15 mins of idle

# Start xss-lock with betterlockscreen
xss-lock -- betterlockscreen -l &

