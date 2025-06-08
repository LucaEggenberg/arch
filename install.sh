#!/bin/bash

clear

# -- color defs --
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
DEBUG="$(tput setaf 3)[DEBUG]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
RESET="$(tput sgr0)"

# -- set log path --

mkdir -p install-logs

LOG="install-logs/00-bootstrap-$(date +%d-%H%M%S).log"

# -- function defs --
execute_script() {
    local script="$1"
    if [ -f "$script" ]; then
        echo "${INFO} executing $script..." | tee -a "$LOG"
        chmod +x "$script";
        if [ -x $script ]; then
            env "$script" | tee -a "$LOG" 2>&1
            if [ $? -ne 0 ]; then
                echo "${ERROR} script '$script' failed" | tee -a "$LOG"
                exit 1
            fi
        else
            echo "${ERROR} failed to make '$script' executable" | tee -a "$LOG"
            exit 1
        fi
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
printf "\n" | tee -a "$LOG"
echo "${INFO} starting bootstrapping..." | tee -a "$LOG"
printf "\n" | tee -a "$LOG"

execute_script "scripts/yay.sh"
printf "\n" | tee -a "$LOG"

execute_script "scripts/ssh.sh"
printf "\n" | tee -a "$LOG"

execute_script "scripts/ansible.sh"
printf "\n" | tee -a "$LOG"

# -- finalize -- 
echo "${OK} bootstrap complete" | tee -a "$LOG"
printf "\n" | tee -a "$LOG"

while true; do
    echo -n "${CAT} Would you like to reboot now? (y/n): " | tee -a "$LOG"
    read -r HYP
    HYP=$(echo "$HYP" | tr '[:upper]' '[:lower]')    

    if [[ "$HYP" == "y" || "$HYP" == "yes" ]]; then
        echo "${INFO} Rebooting now..." | tee -a "$LOG"
        sudo systemctl reboot
        break
    elif [[ "$HYP" == "n" || "$HYP" == "no" ]]; then
        echo "${OK} You chose NOT to reboot." | tee -a "$LOG"
        break
    else
        echo "${WARN} Invalid response. Please answer with 'y' or 'n'." | tee -a "$LOG"
    fi
done

printf "\n%.0s" {1..2} | tee -a "$LOG"
echo "${OK} Script finished." | tee -a "$LOG"