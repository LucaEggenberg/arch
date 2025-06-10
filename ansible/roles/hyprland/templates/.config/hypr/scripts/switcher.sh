#!/bin/bash

HIDDEN_WS_ID=99
SWAP_CURRENT=$1

ANIMATIONS_ENABLED=$(hyprctl getoption animations:enabled -j | jq -r '.int')
AUTOFOCUS_ENABLED=$(hyprctl getoption misc:focus_on_activate -j | jq -r '.int')
FOLLOW_MOUSE_ENABLED=$(hyprctl getoption input:follow_mouse -j | jq -r '.int')

set_keyword() {
    hyprctl keyword $1 $2
}

set_animation() {
    set_keyword animations:enabled $1
}

set_autofocus() {
    set_keyword misc:focus_on_activate $1
}

set_follow_mouse() {
    set_keyword input:follow_mouse $1
}

restore_defaults() {
    set_animation "$ANIMATIONS_ENABLED"
    set_autofocus "$AUTOFOCUS_ENABLED"
    set_follow_mouse "$FOLLOW_MOUSE_ENABLED"
}

# get all windows in HIDDEN_WS
WINDOWS=$(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $HIDDEN_WS_ID)")
if [ -z "$WINDOWS" ]; then
    restore_defaults
    exit 0
fi

# select displaytexts for wofi
DISPLAY_TEXTS=$(echo "$WINDOWS" | jq -r '(.class + " (" + .title + ")")')

# show wofi selectionwindow
WOFI_SELECTION=$(echo "$DISPLAY_TEXTS" | wofi --show dmenu -p "select window:")

if [ -z "$WOFI_SELECTION" ]; then
    # nothing selected
    restore_defaults
    exit 0
fi

SELECTED_WINDOW_ADDR=$(echo "$WINDOWS" \
    | jq -r \
        --arg selected "$WOFI_SELECTION" \
    'select((.class + " (" + .title + ")") == $selected) | .address' \
)

if [ -z "$SELECTED_WINDOW_ADDR" ]; then
    restore_defaults
    notify-send "could not find address for selected window"
    exit 1
fi

CURRENT_WS_ID=$(hyprctl activeworkspace -j | jq -r '.id')
if [ -n "$SWAP_CURRENT" ]; then
    # disable animations & autofocus to prevent flickering
    set_animation 0
    set_autofocus 0
    set_follow_mouse 0

    sleep 0.05

    CURRENT_ADDR=$(hyprctl activewindow -j | jq -r '.address')

    hyprctl dispatch movetoworkspacesilent "$CURRENT_WS_ID",address:"$SELECTED_WINDOW_ADDR"
    hyprctl dispatch movetoworkspacesilent "$HIDDEN_WS_ID",address:"$CURRENT_ADDR"
    hyprctl dispatch focuswindow address:"$SELECTED_WINDOW_ADDR"

    sleep 0.05
    
    restore_defaults
else 
    hyprctl dispatch movetoworkspacesilent "$CURRENT_WS_ID",address:"$SELECTED_WINDOW_ADDR"
    hyprctl dispatch focuswindow address:"$SELECTED_WINDOW_ADDR"
fi
