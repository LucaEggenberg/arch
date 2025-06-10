#!/bin/bash

# variables & initial values
HIDDEN_WS_ID=99

ANIMATIONS_ENABLED=$(hyprctl getoption animations:enabled -j | jq -r '.int')
AUTOFOCUS_ENABLED=$(hyprctl getoption misc:focus_on_activate -j | jq -r '.int')
FOLLOW_MOUSE_ENABLED=$(hyprctl getoption input:follow_mouse -j | jq -r '.int')

CACHE_FILE="$HOME/.cache/switcher_icon_names.cache"
CACHE_TTL=86400

SWAP_CURRENT=$1

# functions
log_time() {
    local label="$1"
    echo "$(date +%s.%N) - $label" >&2
}

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
    log_time "Restoring defaults"
    set_animation "$ANIMATIONS_ENABLED"
    set_autofocus "$AUTOFOCUS_ENABLED"
    set_follow_mouse "$FOLLOW_MOUSE_ENABLED"
}

find_icon() {
    local name="$1"
    if [ -z "$name" ]; then
        echo ""
        return 1
    fi

    local icon_dirs=(
        "$HOME/.local/share/icons"
        "$HOME/.icons"
        "/usr/share/icons"
    )
    local sizes=("scalable" "512x512" "256x256" "128x128" "96x96" "72x72" "64x64" "48x48" "32x32" "24x24" "22x22" "16x16")
    local categories=("apps" "categories" "actions" "mimetypes" "devices" "emblems" "places" "status")
    local extensions=("svg" "png" "xpm")

    local current_gtk_theme=""
    if command -v gsettings &> /dev/null; then
        current_gtk_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
    fi

    local current_kde_theme=""
    if command -v kreadconfig5 &> /dev/null; then
        current_kde_theme=$(kreadconfig5 --file kdeglobals --group Icons --key Theme 2>/dev/null)
    fi

    local active_themes=()
    if [ -n "$current_gtk_theme" ]; then active_themes+=("$current_gtk_theme"); fi
    if [ -n "$current_kde_theme" ]; then active_themes+=("$current_kde_theme"); fi
    active_themes+=("Adwaita" "Breeze" "oxygen" "gnome" "Papirus" "ePapirus" "hicolor")

    for theme in "${active_themes[@]}"; do
        for base_dir in "${icon_dirs[@]}"; do
            local theme_path="$base_dir/$theme"
            if [ ! -d "$theme_path" ]; then
                continue
            fi

            for category in "${categories[@]}"; do
                local icon_path="$theme_path/scalable/$category/${name}.svg"
                if [ -f "$icon_path" ]; then
                    echo "$icon_path"
                    return 0
                fi
            done

            for size in "${sizes[@]}"; do
                if [ "$size" == "scalable" ]; then continue; fi
                for category in "${categories[@]}"; do
                    for ext in "${extensions[@]}"; do
                        local icon_path="$theme_path/${size}/${category}/${name}.${ext}"
                        if [ -f "$icon_path" ]; then
                            echo "$icon_path"
                            return 0
                        fi
                    done
                done
            done
        done
    done

    local pixmap_icon="/usr/share/pixmaps/${name}.png"
    if [ -f "$pixmap_icon" ]; then
        echo "$pixmap_icon"
        return 0
    fi
    pixmap_icon="/usr/share/pixmaps/${name}.svg"
    if [ -f "$pixmap_icon" ]; then
        echo "$pixmap_icon"
        return 0
    fi

    echo ""
    return 1
}

populate_icon_cache() {
    log_time "Populating icon cache..."
    # Clear old cache
    > "$CACHE_FILE"

    # find .desktop files and extract relevant info
    find /usr/share/applications/ -maxdepth 1 -type f -name "*.desktop" -print0 | while IFS= read -r -d $'\0' desktop_file; do
        local app_class=""
        local icon_name=""

        # Try to find StartupWMClass first
        app_class=$(grep -m 1 '^StartupWMClass=' "$desktop_file" | cut -d= -f2-)
        if [ -z "$app_class" ]; then
            # If no StartupWMClass, try to derive from Exec, or use filename
            app_class=$(grep -m 1 '^Exec=' "$desktop_file" | sed 's/.*Exec=\([^[:space:]]*\).*/\1/' | xargs basename)
        fi
        if [ -z "$app_class" ]; then
            # Fallback to filename if no Exec or StartupWMClass found
            app_class=$(basename "$desktop_file" .desktop)
        fi

        icon_name=$(grep -m 1 '^Icon=' "$desktop_file" | cut -d= -f2-)

        if [ -n "$app_class" ] && [ -n "$icon_name" ]; then
            # Store in cache: WM_CLASS=icon_name
            echo "${app_class}=${icon_name}" >> "$CACHE_FILE"
        fi
    done
    log_time "Icon cache populated."
}

find_icon_name() {
    local app_class="$1"
    if [ -z "$app_class" ]; then
        echo ""
        return 1
    fi

    local icon_name=""

    # 1. check cache
    icon_name=$(grep -m 1 "^${app_class}=" "$CACHE_FILE" | cut -d= -f2-)
    if [ -n "$icon_name" ]; then
        echo "$icon_name"
        return 0
    fi

    # 2. if not in cache, try to find .desktop file
    local desktop_file=""
    desktop_file=$(find /usr/share/applications/ -maxdepth 1 -type f -name "*.desktop" -print0 | \
                   xargs -0 grep -lE "^StartupWMClass=${app_class}$|^Exec=.* ${app_class}" 2>/dev/null | head -n 1)

    if [ -z "$desktop_file" ]; then
        desktop_file=$(find /usr/share/applications/ -maxdepth 1 -type f -name "*.desktop" -print0 | \
                       xargs -0 -I {} bash -c 'filename=$(basename "{}" .desktop | tr "[:upper:]" "[:lower:]"); if [[ "$filename" == *'"$app_class"'* ]]; then echo "{}"; exit; fi' 2>/dev/null | head -n 1)
    fi

    if [ -n "$desktop_file" ]; then
        icon_name=$(grep -m 1 '^Icon=' "$desktop_file" | cut -d= -f2-)
        if [ -n "$icon_name" ]; then
            echo "${app_class}=${icon_name}" >> "$CACHE_FILE" # Add to cache for next time
            echo "$icon_name"
            return 0
        fi
    fi

    echo "$app_class"
    return 0
}

build_wofi_list() {
    local windows_json="$1"
    local formatted_items=""

    echo "$windows_json" | \
    jq -r '.[] | select(.workspace.id == '$HIDDEN_WS_ID') | (.class? // "") + "\t" + (.title? // "") + "\t" + (.address? // "")' | \
    while IFS=$'\t' read -r json_class json_title json_address; do
        local icon_path=""
        # escape ampersands and other markup-sensitive characters for wofis text display
        local escaped_json_title=$(echo "$json_title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        local normalized_class=$(echo "$json_class" | sed 's/[^a-zA-Z0-9_-]/_/g' | tr '[:upper:]' '[:lower:]')

        local icon_name=$(find_icon_name "$normalized_class")
        
        if [[ -n "$icon_name" ]]; then
            icon_path=$(find_icon "$icon_name")
        fi

        local display_text="${json_class}"
        if [[ -n "$escaped_json_title" ]]; then
            display_text+=" (${escaped_json_title})"
        fi

        if [[ -n "$icon_path" ]]; then
            printf "img:%s:text:%s\n" "$icon_path" "$display_text"
        else
            printf "img::text:%s\n" "$display_text"
        fi
    done
}

# ensure cache exists
mkdir -p "$(dirname "$CACHE_FILE")"
log_time "Script start"

# check/populate cache if it's too old or doesnt exist
if [ ! -f "$CACHE_FILE" ] || [ "$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))" -gt "$CACHE_TTL" ]; then
    populate_icon_cache & # run in background to not block main script execution
fi

log_time "Fetching hyprctl clients"
WINDOWS_JSON=$(hyprctl clients -j)
log_time "Finished fetching hyprctl clients"

WINDOWS=$(echo "$WINDOWS_JSON" | jq -r ".[] | select(.workspace.id == $HIDDEN_WS_ID)")

if [ -z "$WINDOWS" ]; then
    restore_defaults
    exit 0
fi

log_time "Building wofi list"
DISPLAY_TEXTS=$(build_wofi_list "$WINDOWS_JSON")
log_time "Finished building wofi list"

log_time "Showing wofi selection window"
WOFI_SELECTION=$(echo "$DISPLAY_TEXTS" | wofi --show dmenu -p "select window:")
log_time "Wofi selection received"

if [ -z "$WOFI_SELECTION" ]; then
    restore_defaults
    exit 0
fi

CLEAN_SELECTION=$(echo "$WOFI_SELECTION" | sed 's/^img:[^:]*:text://')

log_time "Finding selected window address"
SELECTED_WINDOW_ADDR=$(echo "$WINDOWS_JSON" \
    | jq -r \
        --arg selected_display_text "$CLEAN_SELECTION" \
        --arg hidden_ws_id "$HIDDEN_WS_ID" \
    '
    .[] |
    select(.workspace.id == ($hidden_ws_id | tonumber)) |
    (.class? // "") as $class |
    (.title? // "") as $title |
    # Re-escape title for comparison with selected_display_text if necessary
    ($class + (if $title != "" then " (" + ($title | gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;")) + ")" else "" end)) as $computed_display_text |
    select($computed_display_text == $selected_display_text) | .address' \
)
log_time "Found selected window address"

if [ -z "$SELECTED_WINDOW_ADDR" ]; then
    restore_defaults
    notify-send "could not find address for selected window"
    exit 1
fi

CURRENT_WS_ID=$(hyprctl activeworkspace -j | jq -r '.id')
if [ -n "$SWAP_CURRENT" ]; then
    log_time "Swapping windows: disabling animations/autofocus"
    set_animation 0
    set_autofocus 0
    set_follow_mouse 0

    sleep 0.05

    CURRENT_ADDR=$(hyprctl activewindow -j | jq -r '.address')

    log_time "Dispatching movetoworkspacesilent and focuswindow"
    hyprctl dispatch movetoworkspacesilent "$CURRENT_WS_ID",address:"$SELECTED_WINDOW_ADDR"
    hyprctl dispatch movetoworkspacesilent "$HIDDEN_WS_ID",address:"$CURRENT_ADDR"
    hyprctl dispatch focuswindow address:"$SELECTED_WINDOW_ADDR"
    log_time "Finished dispatching movetoworkspacesilent and focuswindow"

    sleep 0.05
    
    restore_defaults
else 
    log_time "Moving window: dispatching movetoworkspacesilent and focuswindow"
    hyprctl dispatch movetoworkspacesilent "$CURRENT_WS_ID",address:"$SELECTED_WINDOW_ADDR"
    hyprctl dispatch focuswindow address:"$SELECTED_WINDOW_ADDR"
    log_time "Finished moving window"
fi

log_time "Script end"