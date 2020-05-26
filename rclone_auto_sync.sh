# !/bin/bash
# license GPLv2
# Inspired by https://github.com/bobbintb/backup-bash

local_dir="/Users/hkz/test"
cloud_dir="one_per:test"
if [ "$(uname)"=="Darwin" ]
then
    mac=true
else
    mac=false
fi

# http://stackoverflow.com/questions/1644856/terminate-running-commands-when-shell-script-is-killed
trap 'kill -HUP 0' EXIT

# Sync the local to the cloud
function sync(){
    echo "Sync the local to the cloud"
    rclone sync $local_dir $cloud_dir -P 2>&1
}

# Fetch cloud files if exists differences
function fetch (){
    if [ "$mac" = true ]
    then
        if rclone check $local_dir $cloud_dir 2>&1 | ggrep -P "[1-9][0-9]*( differences)"
        then
            echo "Fetch cloud files"
            rclone sync $cloud_dir $local_dir -P 2>&1
        fi
    else
        if rclone check $local_dir $cloud_dir 2>&1 | grep -P "[1-9][0-9]*( differences)"
        then
            echo "Fetch cloud files"
            rclone sync $cloud_dir $local_dir -P 2>&1
        fi
    fi
}

# Check if fswatch/inotify-tools is installed
if [ "$mac" = true ]
then
    type -P fswatch &> /dev/null || { echo "fswatch command not found"; exit 1; }
else
    type -P inotifywait &> /dev/null || { echo "inotifywait command not found"; exit 1; }
fi

while true
do
    fetch || exit 0
    # Sync with rclone when local files changes
    if [ "$mac" = true ]
    then
        fswatch $local_dir | while read f; do sync; done
    else
        inotifywait -r -e modify, attrib, close_write, move, create, delete \
        --format '%T %:e %f' --timefmt '%c' $local_dir 2>&1 && sync
    fi
done