# Handy Backend

A template with handy scripts to test and run programs as a daemon in the background, with `stdout` & `stderr` logs and log rotation built-in. The target program needs zero modification.

Requires Python 3.6+ for log rotation.

## Setup

> [!NOTE] 
>
> All relative paths are relative to the location of the scripts.

1. Use this template to create a new repository; or copy the scripts to your existing project (any location is fine, but do place them together).
2. Open `start.sh` and modify `CMD` to set the command to run. Add setup commands (change directory, activate virtual environment, etc.) if needed.
3. (Optional) Modify `startd.sh` to change the logging and rotation settings.
    ```bash
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
    PYTHON_CMD=python
    # log rotation script
    LOG_ROTATION_PY=rotatelog.py
    ```

## Usage

`./start.sh`: Run the command in the terminal.

`./startd.sh`: Run the command as a daemon process in the background (return if already running), and also start log rotation using `rotatelog.py`. This script is dependent on `start.sh` and `rotatelog.py`.

- both processes are run in the background with their PIDs stored in `.vars/server.pid` and `.vars/rotate.pid`, and they communicate using a fifo file `.vars/.fifo`. **Do NOT manually modify or delete these files.**
- server logs are stored in `logs/server.log` and rotated every 5MB (can be changed in `startd.sh`)
- rotation logs are stored in `logs/rotate.log` and rotated every 5MB (can be changed in `startd.sh`)

`./statusd.sh`: Check the status of the command and the log rotation process running in the background.

`./stopd.sh`: Stop the command and the log rotation process running in the background.

