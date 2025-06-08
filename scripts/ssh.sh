#!/bin/bash

# -- color defs --
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
DEBUG="$(tput setaf 3)[DEBUG]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"


if sudo systemctl is-enabled sshd &> /dev/null; then
    echo "${OK} sshd service already enabled"
else 
    if ! pacman -Q openssh &> /dev/null; then
        echo "${INFO} openssh not found, installing..."
        sudo pacman -S --noconfirm openssh
    
        if [ $? -ne 0 ]; then
            echo "${ERROR} Failed to install openssh"
            exit 1
        fi
        echo "${OK} openssh installed"
    else 
        echo "${OK} openssh already installed"
    fi
    
    echo "${INFO} enable and start sshd service"
    sudo systemctl enable --now sshd
    if [ $? -ne 0 ]; then
        echo "${ERROR} failed to enable sshd service"
        exit 1
    fi

    echo "${OK} openssh installed and enabled"
fi