#!/bin/bash

# -- color defs --
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
DEBUG="$(tput setaf 3)[DEBUG]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"

if command -v yay &> /dev/null; then
    echo "${OK} yay already installed --skipping"
else 
    echo "${INFO} yay not found, installing yay..."

    if ! command -v git &> /dev/null; then
        echo "${ERROR} git not found, how did you run this script?! 🤨"
        exit 1
    fi

    echo "${INFO} clone yay repo..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay

    if [ $? -ne 0 ]; then
        echo "${ERROR} failed to clone repository"
        exit 1
    fi

    echo "${INFO} installing yay..."
    cd /tmp/yay
    makepkg -si --noconfirm
    if [ $? -ne 0 ]; then
        echo "${ERROR} failed to build and install yay"
        exit 1
    fi

    echo "${DEBUG} cleanup"
    rm -rf /tmp/yay

    echo "${OK} yay has been installed"
fi