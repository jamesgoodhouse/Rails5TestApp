#!/bin/sh

. /docker-lib.sh

start_docker

docker load -i ruby-2.3.1-image/image
docker tag "$(cat ruby-2.3.1-image/image-id)" "$(cat ruby-2.3.1-image/repository):$(cat ruby-2.3.1-image/tag)"

cp project-code/.dockerignore .

docker build -f project-code/Dockerfile -t jamgood96/rails5testapp:latest .

mkdir -p project-image-tar

docker save jamgood96/rails5testapp:latest > project-image-tar/image.tar
