#!/bin/bash

# Change to the directory where the script is located
CURRENT_DIR=$(dirname ${BASH_SOURCE[0]})
cd $CURRENT_DIR

# dirs
VAR_DIR=.var

# PID file
PID_FILE=$VAR_DIR/server.pid
PID_ROTATE_FILE=$VAR_DIR/rotate.pid

# colors for output
LIGHT_RED='\033[1;31m'
LIGHT_CYAN='\033[1;36m'
NC='\033[0m'

check() {
  local PID_FILE=$1
  local PROCESS_NAME=$2
  
  # check if PID file exists
  if [ ! -f "$PID_FILE" ]; then
      printf "${LIGHT_RED}$PROCESS_NAME process is not running (no PID file: $PID_FILE)${NC}\n"
      return 1
  fi

  # Read the process ID
  PID=$(cat $PID_FILE)
  # show process info
  ps axo user,uid,pid,ppid,rss,stime,tty,time,command | awk -v pid=$PID 'NR==1 || $3 == pid || $4 == pid'
  if [ $? -ne 0 ]; then
    printf "${LIGHT_RED}$PROCESS_NAME process is not running (should be at PID $PID)${NC}\n"
    return 1
  else
    printf "${LIGHT_CYAN}$PROCESS_NAME process is running with PID ${LIGHT_RED}$PID${NC}\n"
  fi
}

check $PID_FILE "Server"
check $PID_ROTATE_FILE "Log rotation"

