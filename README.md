# Handy Backend

## Setup

Open `start.sh` and modify `CMD` to set the command to run.

## Usage

`./start.sh`: Run the command in the terminal.

`./startd.sh`: Run the command as a daemon process in the background, and also start log rotation using `rotatelog.py`.

- both processes are run in the background with their PIDs stored in `.vars/server.pid` and `.vars/rotate.pid`, and they communicate using a fifo file `.vars/.fifo`. **Do NOT manually modify or delete these files.**
- server logs are stored in `logs/server.log` and rotated every 5MB (can be changed in `startd.sh`)
- rotation logs are stored in `logs/rotate.log`

`./statusd.sh`: Check the status of the command and the log rotation process running in the background.

`./stopd.sh`: Stop the command and the log rotation process running in the background.

