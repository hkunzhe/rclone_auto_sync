# !/bin/bash
# license GPLv2
# Inspired by https://github.com/bobbintb/backup-bash

local_dir="test"
cloud_dir="one_per:test"
log_file="backuperrors.txt"
# http://stackoverflow.com/questions/1644856/terminate-running-commands-when-shell-script-is-killed
trap 'kill -HUP 0' EXIT

# Sync the local to the cloud
function sync(){
    if rclone sync $local_dir $cloud_dir -P  2>&1 >>$log_file
    then
        echo "Sync the local to the cloud"
    else
        echo "Sync failed"
    return 1
    fi
}

# Fetch cloud files if exists differences
function fetch (){
    if rclone check $local_dir $cloud_dir 2>&1 | grep -P "[1-9][0-9]*( differences)"
    then
        echo "Fetch cloud files"
        rclone sync $cloud_dir $local_dir 2>&1 >> $log_file
    fi
}

#Check if inotify-tools is installed
type -P inotifywait &>/dev/null || { echo "inotifywait command not found."; exit 1; }

while true
do

fetch || exit 0

#Sync with rclone when local files changes
inotifywait -r -e modify, attrib, close_write, move, create, delete  --format '%T %:e %f' --timefmt '%c' $local_dir  2>&1 >> $log_file && sync

done
