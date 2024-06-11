#!/bin/bash

# change to the directory where the script is located
CURRENT_DIR=$(dirname ${BASH_SOURCE[0]})
cd $CURRENT_DIR

# optional: add custom setup here


# CHANGE THIS: the actual command you want to run
CMD=

# check if CMD is set
LIGHT_RED='\033[1;31m'
NC='\033[0m'
if [ -z "$CMD" ]; then
    printf "${LIGHT_RED}Nothing to run. Please set the CMD variable in start.sh${NC}\n"
    exit 1
fi

# run the command
exec $CMD
