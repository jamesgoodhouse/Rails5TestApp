#!/bin/sh

. /docker-lib.sh

start_docker

docker load -i ruby-image/image
docker tag "$(cat ruby-image/image-id)" "$(cat ruby-image/repository):$(cat ruby-image/tag)"

cd project-code

docker build -t jamgood96/rails5testapp:latest .

cd ..

mkdir -p project-image-tar

docker save jamgood96/rails5testapp:latest > project-image-tar/image.tar

echo `ls -la`
echo `ls -la project-image-tar`

echo `pwd`

echo `docker images`
