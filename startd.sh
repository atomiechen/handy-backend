#!/bin/bash
# Author: Atomie CHEN (atomic_cwh@163.com)
# Repository: https://github.com/atomiechen/handy-backend
# License: MIT


# -------- BEGIN SETTINGS --------
# Note: relative paths are based on location of this script
# log directory
LOG_DIR=logs
# ---
# log file (will be rotated)
LOG_PATH=$LOG_DIR/server.log
# max log size in MB
MAX_LOG_SIZE=5
# ---
# log file of log rotation script (will be rotated)
ROTATE_FILE=$LOG_DIR/rotate.log
# max log size for rotation output in MB
MAX_ROTATION_LOG_SIZE=5
# ---
# python executable used to run log rotation script
PYTHON_CMD=python3
# log rotation script
LOG_ROTATION_PY=rotatelog.py
# -------- END SETTINGS --------


# [!IMPORTANT] do not manually change these files
# dir for PID files and other stuff
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

# change to the directory where the script is located
CURRENT_DIR=$(dirname ${BASH_SOURCE[0]})
cd $CURRENT_DIR

# test if python is installed
if ! command -v $PYTHON_CMD &> /dev/null; then
    printf "${LIGHT_RED}Cannot run '$PYTHON_CMD'. Python is required for log rotation.${NC}\n"
    exit 1
fi

# create VAR_DIR or LOG_DIR if not exists
if [ ! -d "$VAR_DIR" ]; then
    mkdir -p $VAR_DIR
fi
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p $LOG_DIR
fi

# if PID file exits, exit
check_pid() {
    local PID_FILE=$1
    local PROCESS_NAME=$2
    if [ -f "$PID_FILE" ]; then
        printf "${LIGHT_RED}$PROCESS_NAME PID file $PID_FILE exists. $PROCESS_NAME process may still be running (run stopd.sh to stop it).${NC}\n"
        exit 1
    fi
}
check_pid $PID_FILE "Server"
check_pid $PID_ROTATE_FILE "Log rotation"

# check FIFO
if [ -e $FIFO_PATH ]; then
    if [ ! -p $FIFO_PATH ]; then
        # If it exists but is not a FIFO, remove it
        rm -f $FIFO_PATH
        mkfifo $FIFO_PATH
    fi
else
    mkdir -p $(dirname $FIFO_PATH)
    mkfifo $FIFO_PATH
fi

check_start_status() {
    local PID_FILE=$1
    local PROCESS_NAME=$2
    local PID=$(cat $PID_FILE)
    if ! ps -p $PID > /dev/null ; then
        printf "${LIGHT_RED}$PROCESS_NAME process failed to start (PID $PID)${NC}\n"
        exit 1
    fi
    printf "${LIGHT_CYAN}$PROCESS_NAME process (parent PID ${LIGHT_RED}$PID${LIGHT_CYAN}) running${NC}\n"
}

# start log rotation
nohup $PYTHON_CMD -u $LOG_ROTATION_PY --fifo-path $FIFO_PATH --log-path $LOG_PATH --max-log-size $MAX_LOG_SIZE \
    --rotation-log-path $ROTATE_FILE --max-rotation-log-size $MAX_ROTATION_LOG_SIZE > /dev/null 2>&1 &
# write PID to file
echo $! > $PID_ROTATE_FILE
# check if log rotation is running
check_start_status $PID_ROTATE_FILE "Log rotation"

# start server
nohup ./start.sh >> $FIFO_PATH 2>&1 &
# write PID to file
echo $! > $PID_FILE
# check if server is running
check_start_status $PID_FILE "Server"

