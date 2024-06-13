# Author: Atomie CHEN (atomic_cwh@163.com)
# Repository: https://github.com/atomiechen/handy-backend
# License: MIT

import os
import stat
from datetime import datetime
import argparse
import logging
from logging.handlers import RotatingFileHandler
import sys
import signal


logger = logging.getLogger("rotatelog")

class FixedSizeRotatingFileHandler(RotatingFileHandler):
    def __init__(self, filename, maxBytes):
        super().__init__(filename, maxBytes=maxBytes)

    def doRollover(self):
        if self.stream:
            self.stream.close()
            self.stream = None
        # Create timestamped filename for the rollover logs
        current_time = datetime.now().strftime('.%Y%m%d-%H:%M:%S')
        self.rotate(self.baseFilename, self.baseFilename + current_time)
        self.stream = self._open()


def signal_handler(signum, frame):
    logger.info(f"Received signal {signum}, shutting down.")
    sys.exit(0)

# Set up signal handlers
signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

def make_file_dir(file_path):
    par_dir = get_file_dir(file_path)
    make_dir(par_dir)

def get_file_dir(file_path):
    return os.path.dirname(file_path)

def make_dir(dir):
    dir = os.path.abspath(dir)
    if not os.path.exists(dir):
        os.makedirs(dir, exist_ok=True)

def check_fifo(fifo_path):
    # Check if the path exists
    if os.path.exists(fifo_path):
        # If it exists, check if it's not a FIFO
        if not stat.S_ISFIFO(os.stat(fifo_path).st_mode):
            raise ValueError(f"{fifo_path} exists and is not a FIFO")
    else:
        raise ValueError(f"{fifo_path} does not exist")

def need_rotate(log_path, max_log_size):
    return os.path.getsize(log_path) >= max_log_size and max_log_size > 0

def rotate_log(log_path):
    current_time = datetime.now().strftime('.%Y%m%d-%H:%M:%S')
    new_name = log_path + current_time
    logger.info(f"Rotating {log_path} to {new_name}")
    if os.path.exists(new_name):
        logger.warning(f"{new_name} already exists, skip renaming")
    else:
        make_file_dir(new_name)
        os.rename(log_path, new_name)

def loop_to_log(bin_fd, log_path, max_log_size):
    while True:  # loop once whenever need to rotate
        with open(log_path, "ab") as log_file:
            while True:
                try:
                    # read byte by byte in binary mode to avoid decoding 
                    # error caused by utf8 character truncation
                    byte = bin_fd.read(1)
                    if byte:
                        log_file.write(byte)
                        log_file.flush()  # immediately write the content to the file
                        # When a newline character is read, check if 
                        # rotation is needed; if so, break the loop
                        if byte == b'\n' and need_rotate(log_path, max_log_size):
                            break
                    else:
                        logger.info(f"Read EOF, now closing...")
                        return
                except Exception as e:
                    logger.exception(f"Exception in while loop: {e}")
        rotate_log(log_path)  # rotate log file

def catch_exception(func):
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            logger.exception(f"Exception in {func.__name__}: {e}")
    return wrapper

@catch_exception
def main(fifo_path, log_path, max_log_size, rotation_log_path, max_rotation_log_size):
    # Configure logging
    rh = None
    if rotation_log_path:
        rh = FixedSizeRotatingFileHandler(rotation_log_path, maxBytes=max_rotation_log_size)
    logging.basicConfig(
        format='%(asctime)s.%(msecs)03d - %(process)d - %(levelname)s - %(message)s', 
        level=logging.INFO, 
        datefmt='%Y-%m-%d %H:%M:%S', 
        handlers=[rh] if rh else None, 
    )
    logger.info(f"Start logging and rotating: {log_path=} {max_log_size=} {rotation_log_path=} {max_rotation_log_size=}")
    if fifo_path:
        logger.info(f"Reading from FIFO: {fifo_path}")
        check_fifo(fifo_path)
        make_file_dir(log_path)
        with open(fifo_path, "rb") as fifo:
            loop_to_log(fifo, log_path, max_log_size)
    else:
        logger.info("Reading from stdin")
        loop_to_log(sys.stdin.buffer, log_path, max_log_size)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Log rotation utility")
    parser.add_argument("--fifo-path", help="FIFO file path; if not provided, read from stdin", default=None)
    parser.add_argument("--log-path", help="Log file path", required=True)
    parser.add_argument("--max-log-size", help="Max log file size (MB); 0 for no rotation", type=int, required=True)
    parser.add_argument("--rotation-log-path", help="Path of the log output of this rotation process; if not provided, output to stdout", default=None)
    parser.add_argument("--max-rotation-log-size", help="Max file size (MB) for this rotation log; 0 for no rotation", type=int, default=5)
    args = parser.parse_args()
    main(args.fifo_path, args.log_path, args.max_log_size * 1024 * 1024, args.rotation_log_path, args.max_rotation_log_size * 1024 * 1024)
    logger.info("Process finished.")
