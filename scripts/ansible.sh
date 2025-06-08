#!/bin/bash

# -- color defs --
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
DEBUG="$(tput setaf 3)[DEBUG]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"


if command -v ansible &> /dev/null; then
    echo "${OK} ansible is already installed"
else 
    if ! command -v python &> /dev/null; then
        echo "${INFO} Python not found, installing..:"
        sudo pacman -S --noconfirm python
        if [ $? -ne 0 ]; then
            echo "${ERROR} Failed to install python"
            exit 1
        fi
        echo "${OK} python installed"
    else 
        echo "${OK} python already installed"
    fi

    if ! pacman -Q python-pip &> /dev/null; then
        echo "${INFO} python-pip not found, installing..."
        sudo pacman -S --noconfirm python-pip
        if [ $? -ne 0 ]; then
            echo "${ERROR} Failed to install python-pip"
            exit 1
        fi
        echo "${OK} python-pip installed"
    else 
        echo "${OK} python-pip already installed"
    fi

    echo "${Info} installing ansible"
    sudo pacman -S --noconfirm ansible
    if [ $? -ne 0 ]; then
        echo "${ERROR} Failed to install ansible"
        exit 1
    fi
    
    echo "${OK} ansible installed"
fi