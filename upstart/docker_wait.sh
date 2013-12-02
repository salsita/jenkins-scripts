#!/bin/sh

. /etc/default/docker

echo "Determining if docker is running..."
set +e; ${DOCKER} ps; RC=$?; set -e
echo "${RC} (anything non-zeroish means no)."

i=0

while [ ${RC} -ne 0 ]; do

    if [ ${i} -ge 10 ]; then
	    echo "I can't connect to Docker no matter what. Giving up. Byes."
	    exit 1 
    fi

    i=`expr ${i} + 1`

    echo "I'm going to sleep a little bit now and then I'll try again, aaaight?"
    sleep 4 
    set +e; ${DOCKER} ps; RC=$?; set -e

done

echo "Twas' bout time. Docker up and running."


