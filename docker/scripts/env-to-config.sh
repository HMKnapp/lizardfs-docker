#!/bin/bash

# Function to update settings.cfg
update_setting() {
    local file="$1"
    local variable="$2"
    local value="$3"
    local comment="$4"

    # Escape special characters in value (if any)
    value_escaped=$(printf '%s\n' "$value" | sed -e 's/[]\/$*.^[]/\\&/g')

    # Use sed to update the specified file
    sed -i "s|^\($variable[[:space:]]*=[[:space:]]*\).*|\1$value_escaped|; \
            s|^\(#[[:space:]]*$variable[[:space:]]*=[[:space:]]*\).*|\1$value_escaped|" "$file"
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
        env_vars=(LABEL LOCK_MEMORY MASTER_HOST HDD_LEAVE_SPACE_DEFAULT ENABLE_LOAD_FACTOR REPLICATION_BANDWIDTH_LIMIT_KBPS)
        ;;
    master)
        file=lizardfs-master.cfg
        env_vars=(MASTER_CONFIG_1 MASTER_CONFIG_2 MASTER_CONFIG_3)
        ;;
    metalogger)
        file=lizardfs-metalogger.cfg
        env_vars=(METALOGGER_CONFIG_1 METALOGGER_CONFIG_2 METALOGGER_CONFIG_3)
        ;;
    cgiserver)
        file=lizardfs-cgiserver.cfg
        env_vars=(CGI_CONFIG_1 CGI_CONFIG_2 CGI_CONFIG_3)
        ;;
    "disks")
        file="hdd.cfg"
        # Read the list of disk paths from the DISKS environment variable
        IFS=" " read -r -a disk_paths <<< "${DISKS}"
        ;;
    *)
        echo "Invalid parameter. Available options: chunkserver, master, metalogger, cgiserver, uraft"
        exit 1
        ;;
esac

# Loop through the list of environment variables
if [ -n "$env_vars" ]; then
for var in "${env_vars[@]}"; do
    # Check if the environment variable is set
    if [ -n "${!var+x}" ]; then
        # Get the value of the environment variable
        value="${!var}"
        
        # Check if the line exists and uncomment if necessary
        if grep -qE "^\s*$var\s*=" "$file"; then
            update_setting "$file" "$var" "$value" ""
        elif grep -qE "^\s*#$var\s*=" "$file"; then
            update_setting "$file" "$var" "$value" "#"
        else
            # If the line does not exist, add a new line to the end of the file
            echo "$var = $value" >> "$file"
        fi
    fi
done
fi

# Handle the "disks" parameter
if [ -n "$disk_paths" ]; then
    # Remove existing disk lines from hdd.cfg
    sed -i '/^\s*[/\*]/d' "$file"
    
    # Write each disk path to hdd.cfg
    for path in "${disk_paths[@]}"; do
        echo "$path" >> "$file"
    done
fi
