#!/bin/bash

# Change to the directory where the script is located
CURRENT_DIR=$(dirname ${BASH_SOURCE[0]})
cd $CURRENT_DIR

# you may need to change these
PYTHON_CMD=python
LOG_ROTATION_PY=rotatelog.py

# dirs
VAR_DIR=.var
LOG_DIR=logs

# create VAR_DIR or LOG_DIR if not exists
if [ ! -d "$VAR_DIR" ]; then
    mkdir -p $VAR_DIR
fi
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p $LOG_DIR
fi

# log file (will be rotated)
LOG_PATH=$LOG_DIR/server.log
# max log size in MB
MAX_LOG_SIZE=5
# log of log rotation
ROTATE_FILE=$LOG_DIR/rotate.log

# [!IMPORTANT] do not manually change these files
# PID files of server and log rotation
PID_FILE=$VAR_DIR/server.pid
PID_ROTATE_FILE=$VAR_DIR/rotate.pid
# FIFO path
FIFO_PATH=$VAR_DIR/.fifo

# colors for output
LIGHT_RED='\033[1;31m'
LIGHT_CYAN='\033[1;36m'
NC='\033[0m'

# if PID file exits, exit
check_pid() {
    local PID_FILE=$1
    local PROCESS_NAME=$2
    if [ -f "$PID_FILE" ]; then
        printf "${LIGHT_RED}$PROCESS_NAME PID file $PID_FILE exists. $PROCESS_NAME process may still be running.${NC}\n"
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
nohup $PYTHON_CMD -u $LOG_ROTATION_PY --fifo-path $FIFO_PATH --log-path $LOG_PATH --max-log-size $MAX_LOG_SIZE >> $ROTATE_FILE 2>&1 &
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

