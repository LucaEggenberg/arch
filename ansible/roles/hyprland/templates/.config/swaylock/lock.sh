#!/bin/bash

color=303446
bs-hl-color=f2d5cf
caps-lock-bs-hl-color=f2d5cf
caps-lock-key-hl-color=a6d189
inside-color=00000000
inside-clear-color=00000000
inside-caps-lock-color=00000000
inside-ver-color=00000000
inside-wrong-color=00000000
key-hl-color=a6d189
layout-bg-color=00000000
layout-border-color=00000000
layout-text-color=c6d0f5
line-color=00000000
line-clear-color=00000000
line-caps-lock-color=00000000
line-ver-color=00000000
line-wrong-color=00000000
ring-color=babbf1
ring-clear-color=f2d5cf
ring-caps-lock-color=ef9f76
ring-ver-color=8caaee
ring-wrong-color=ea999c
separator-color=00000000
text-color=c6d0f5
text-clear-color=f2d5cf
text-caps-lock-color=ef9f76
text-ver-color=8caaee
text-wrong-color=ea999c

# Execute swaylock with your chosen options
swaylock \
--screenshots \                 # Take a screenshot of the desktop and use it as background
--clock \                       # Show a clock
--indicator \                   # Show the password indicator circle
--indicator-idle-visible \      # Keep the indicator visible even when idle
--indicator-radius 100 \        # Radius of the indicator circle
--indicator-thickness 7 \       # Thickness of the indicator circle
--effect-blur 7x5 \             # Apply a blur effect to the background (radius x sigma)

--fade-in 0.2 \                 # Fade in effect duration
--font "Hack Nerd Font" \       # Font for the clock and input text
--font-size 20 \                # Font size for clock and input text

--daemonize \                   # Run in background (optional, but clean)
--ignore-empty-password \       # Don't require a password if user has no password set (use with caution)

--input-idle-timeout 10         # Dim screen after 10 seconds of idle input
--grace 5                       # Allow 5 seconds to enter password after starting (before immediate lock)
--grace-no-mouse \              # Don't reset grace period on mouse movement
--grace-no-touch \              # Don't reset grace period on touch input