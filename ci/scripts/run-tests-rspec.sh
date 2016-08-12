#!/bin/sh

. /docker-lib.sh

start_docker

docker load -i project-image-tar/image.tar

docker run --rm jamgood96/rails5testapp bundle exec rspec
