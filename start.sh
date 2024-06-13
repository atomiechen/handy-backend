#!/bin/bash
# Author: Atomie CHEN (atomic_cwh@163.com)
# Repository: https://github.com/atomiechen/handy-backend
# License: MIT


######## BEGIN SETTINGS ########
# optional: add custom setup here (change directory, activate virtual environment, etc.)


# CHANGE THIS: the actual command you want to run
CMD=""
######## END SETTINGS ########


# change to the directory where the script is located
CURRENT_DIR=$(dirname ${BASH_SOURCE[0]})
cd $CURRENT_DIR

# check if CMD is set
LIGHT_RED='\033[1;31m'
LIGHT_CYAN='\033[1;36m'
NC='\033[0m'
if [ -z "$CMD" ]; then
    printf "${LIGHT_RED}Nothing to run. Please set the CMD variable in ${LIGHT_CYAN}start.sh${NC}\n"
    exit 1
fi

# run the command
exec $CMD
