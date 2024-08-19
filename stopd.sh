#!/bin/bash
# Author: Atomie CHEN (atomic_cwh@163.com)
# Repository: https://github.com/atomiechen/handy-backend
# License: MIT

# dirs (relative paths are based on location of this script)
VAR_DIR=.var

# PID files of server and log rotation
PID_FILE=$VAR_DIR/server.pid
PID_ROTATE_FILE=$VAR_DIR/rotate.pid
# FIFO path
FIFO_PATH=$VAR_DIR/.fifo

# colors for output
LIGHT_RED='\033[1;31m'
LIGHT_CYAN='\033[1;36m'
NC='\033[0m'

check_and_stop() {
    local PID_FILE=$1
    local PROCESS_NAME=$2

    # check if PID file exists
    if [ ! -f "$PID_FILE" ]; then
        echo "$PROCESS_NAME process is not running (no PID file: $PID_FILE)."
        # nothing need to stop
        return 1
    fi

    # Read the process ID
    local PID=$(cat $PID_FILE)
    local RET=0
    if ! ps -p $PID > /dev/null 2>&1; then
        # PID not running
        printf "${LIGHT_RED}$PROCESS_NAME process (PID ${LIGHT_CYAN}$PID${LIGHT_RED}) is not running${NC}\n"
        RET=1
    else
        # kill children processes
        pkill -P $PID
        # kill parent process
        kill $PID
        # wait until the process is killed
        printf "Waiting for $PROCESS_NAME process (PID $PID) to stop...\n"
        while ps -p $PID > /dev/null ; do
            sleep 1
        done
        printf "${LIGHT_CYAN}$PROCESS_NAME process (parent PID ${LIGHT_RED}$PID${LIGHT_CYAN}) killed${NC}\n"
    fi
    # remove useless PID file if exists
    rm $PID_FILE > /dev/null 2>&1
    return $RET
}

check_and_stop $PID_FILE "Server"
check_and_stop $PID_ROTATE_FILE "Log rotation"

# remove FIFO
if [ -p "$FIFO_PATH" ]; then
    rm $FIFO_PATH
    printf "${LIGHT_CYAN}FIFO deleted${NC}\n"
fi
