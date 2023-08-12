#!/bin/bash

# Function to update .cfg files settings
update_setting() {
    local file="$1"
    local variable="$2"
    local value="$3"
    local comment="$4"

    # Escape special characters in value (if any)
    value_escaped=$(printf '%s\n' "$value" | sed -e 's/[]\/$*.^[]/\\&/g')

    # Use sed to update the specified file
    sed -i "s|^\(#[[:space:]]\)\?\($variable[[:space:]]*=[[:space:]]*\).*|\2$value_escaped|" "$file"
}

# Check if a parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <parameter>"
    exit 1
fi

# Select the appropriate file and env_vars based on the parameter value
case "${1}" in
    chunkserver)
        file=mfschunkserver.cfg
        # map to avoid conflicts with the environment variables of the same name
        LOCK_MEMORY=${CS_LOCK_MEMORY}
        env_vars=(LABEL LOCK_MEMORY MASTER_HOST HDD_LEAVE_SPACE_DEFAULT ENABLE_LOAD_FACTOR REPLICATION_BANDWIDTH_LIMIT_KBPS)
        ;;
    master)
        file=mfsmaster.cfg
        env_vars=(PERSONALITY ADMIN_PASSWORD LOCK_MEMORY PREFER_LOCAL_CHUNKSERVER ENDANGERED_CHUNKS_PRIORITY)
        ;;
    metalogger)
        file=mfsmetalogger.cfg
        # map to avoid conflicts with the environment variables of the same name
        LOCK_MEMORY=${ML_LOCK_MEMORY}
        env_vars=(MASTER_HOST LOCK_MEMORY BACK_META_KEEP_PREVIOUS META_DOWNLOAD_FREQ)
        ;;
    disks)
        file=mfshdd.cfg
        # Read the list of disk paths from the DISKS environment variable
        IFS=" " read -r -a disk_paths <<< "${DISKS}"
        ;;
    *)
        echo "Invalid parameter. Available options: chunkserver, master, metalogger, cgiserver, uraft"
        exit 1
        ;;
esac

file="/etc/lizardfs/$file"

# Loop through the list of environment variables
if [ -n "$env_vars" ]; then
for var in "${env_vars[@]}"; do
    # Check if the environment variable is set
    if [ -n "${!var+x}" ]; then
        # Get the value of the environment variable
        value="${!var}"
        if [ -n "$value" ]; then
            update_setting "$file" "$var" "$value" ""
        fi
    fi
done
fi

# Add or replace the "disks"
if [ -n "$disk_paths" ]; then
    # Remove existing disk lines from hdd.cfg
    sed -i '/^\s*[/\*]/d' "$file"
    
    # Write each disk path to mfshdd.cfg
    for dir in "${disk_paths[@]}"; do
        if [ ! -d "$LOCAL_MOUNT_ROOT/$dir" ]; then
            echo "Warning: $LOCAL_MOUNT_ROOT/$dir does not exist on host machine!"
            sleep 10
        fi
        echo "$LOCAL_MOUNT_ROOT/$dir" >> "$file"
    done
fi
