#!/bin/bash

clear

# -- color defs --
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
DEBUG="$(tput setaf 3)[DEBUG]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"

# -- set log path --
LOG="install-logs/$(date + %Y-%m-%d_%H-%M-%S).log"
mkdir -p install-logs

# -- function defs --
execute_script() {
    local script="$1"
    if [ -f "$script" ]; then
        chmod +x "$script";
        echo "${INFO} running $script..." | tee -a "$LOG"
    else 
        echo "${ERROR} script $script not found" | tee -a "$LOG"
    fi
}

# -- pre-checks --
if [[ $EUID -eq 0 ]]; then
    echo "${ERROR} This script should ${WARNING}NOT${RESET} be executed as root!! Exiting......." | tee -a "$LOG"
    exit 1
fi

if ! pacman -Q base-devel &> /dev/null; then
    echo "${NOTE} installing base-devel..." | tee -a "$LOG"
    sudo pacman -S --noconfirm base-devel | tee -a "$LOG"

    if [ $? -ne 0]; then
        echo "${ERROR} failed installing base-devel. exiting script" | tee -a "$LOG"
        exit 1
    fi
else 
    echo "${OK} base-devel already installed" | tee -a "$LOG"
fi

# -- installation --
echo "${INFO} installing yay..." | tee -a "$LOG"
execute_script "scripts/yay.sh"
sleep 1