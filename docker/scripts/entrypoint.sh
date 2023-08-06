#!/bin/bash

# decide which server to start according to ENV
case "${ROLE}" in
    chunkserver)
        # set chunkserver config
        env-to-config.sh chunkserver

        # init disks config
        env-to-config.sh disks

        echo "To temporarily change or remove disks of a running chunkserver"
        echo "simply edit /configs/mfshdd.cfg."
        echo
        echo "To make changes permanent, edit .env or pass DISKS variable and restart the container."
        echo

        exec mfschunkserver -d start
        ;;
    cgiserver)
        # cgiserver has mfsmaster hardcoded so we need the IP of MASTER_HOST
        master_ip=$(getent hosts $MASTER_HOST)
        master_ip=${master_ip%% *}
        # add IP of MASTERHOST as mfsmaster to /etc/hosts
        su -c 'echo "'$master_ip' mfsmaster" >> /etc/hosts' root
        exec lizardfs-cgiserver start
        ;;
    master)
        if [[ ! -f /var/lib/lizardfs/metadata.mfs ]]; then
            echo "Metadata not found. Aborting..."
            echo "To avoid accidentally overwriting shadow copies with an empty db"
            echo "you must do the initial step manually by"
            echo "copying ./config/metadata.mfs.new"
            echo "to ./data/master/metadata.mfs and then restart the container."
            exit 1
        fi

        # set master config
        env-to-config.sh master

        exec mfsmaster -d start
        ;;
    metalogger)
        # set metalogger config
        env-to-config.sh metalogger

        exec mfsmetalogger -d start
        ;;
    uraft)
        # Function to stop the uraft daemon
        stop() {
            kill ${1} || kill -9 ${1}
            RETVAL=$?
            exit ${RETVAL}
        }

        # set master config
        env-to-config.sh master

        lizardfs-uraft &
        local pid=$!
        
        trap "stop ${pid}" SIGTERM
        exec mfsmaster -d -o ha-cluster-managed -o initial-personality=shadow start
        ;;
    *)
        echo "You must specify which daemon to start!"
        echo "e.g. docker-compose up lizardfs-master
"
        exit 1
        ;;
esac
