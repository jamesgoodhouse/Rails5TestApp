#!/bin/sh

. /docker-lib.sh

start_docker

echo BUILDING IMAGE

echo $(docker ps -a)
echo ---------
echo $(pwd)
echo $(ls /)
echo $(ls code-repo)
