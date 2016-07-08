#!/bin/bash

set -eo pipefail

if [ "$1" == "mesos-master" ]; then
    su-exec mesos mesos-master
elif [ "$1" == "mesos-slave" ]; then
    su-exec mesos mesos-slave
fi

exec "$@"