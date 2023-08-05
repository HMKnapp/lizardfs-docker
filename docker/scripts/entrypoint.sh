#!/bin/bash

# decide which server to start according to ENV
case "${ROLE}" in
    chunkserver)
        # Function to stop the chunkserver daemon
        stop() {
            timeout 60 mfschunkserver stop
            RETVAL=$?
            exit ${RETVAL}
        }

        # set chunkserver config
        env-to-config.sh chunkserver

        # init disks config
        env-to-config.sh disks

        echo "To temporarily change or remove disks of a running chunkserver"
        echo "simply edit /configs/mfshdd.cfg."
        echo
        echo "To make changes permanent, edit .env or pass DISKS variable and restart the container."
        echo

        mfschunkserver start &
        trap stop SIGTERM
        ;;
    cgiserver)
        # Function to stop the chunkserver daemon
        stop() {
            kill ${1} || kill -9 ${1}
            RETVAL=$?
            exit ${RETVAL}
        }

        lizardfs-cgiserver start &
        local pid=$!
        trap "stop ${pid}" SIGTERM
        ;;
    master)
        # Function to stop the master daemon
        stop() {
            timeout 60 mfsmaster stop
            RETVAL=$?
            exit ${RETVAL}
        }

        if [[ ! -f /var/lib/mfs/metadata.mfs ]]; then
            echo "Metadata not found. Aborting..."
            echo "To avoid accidentally overwriting shadow copies with an empty db"
            echo "you must do the initial step manually by"
            echo "copying ./config/metadata.mfs.new"
            echo "to ./data/master/metadata.mfs and then restart the container."
            exit 1
        fi

        # set master config
        env-to-config.sh master

        mfsmaster start &
        trap stop SIGTERM
        ;;
    metalogger)
        # Function to stop the metalogger daemon
        stop() {
            timeout 60 mfsmetalogger stop
            RETVAL=$?
            exit ${RETVAL}
        }

        # set metalogger config
        env-to-config.sh metalogger

        mfsmaster start &
        trap stop SIGTERM
        ;;
    uraft)
        # Function to stop the uraft daemon
        stop() {
            kill ${1} || kill -9 ${1}
            timeout 60 mfsmaster -o ha-cluster-managed -o initial-personality=shadow stop
            RETVAL=$?
            exit ${RETVAL}
        }

        # set master config
        env-to-config.sh master

        mfsmaster -o ha-cluster-managed -o initial-personality=shadow start &
        local pid=$!
        trap "stop ${pid}" SIGTERM
        ;;
    *)
        echo "You must specify which daemon to start!"
        echo "e.g. docker-compose up lizardfs-master
"
        exit 1
        ;;
esac

sleep infinity
