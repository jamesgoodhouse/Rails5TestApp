#!/bin/sh

. /docker-lib.sh

start_docker

docker load -i ruby-dev-image/image
docker load -i ruby-image/image

echo -----------
echo `docker images`
echo -----------

cd code-repo

docker run --rm -v "$PWD":/worker -w /worker iron/ruby:dev sh -c 'bundle config --local build.nokogiri --use-system-libraries && bundle install --standalone --clean'

docker build . taco_tuesday

echo $(docker ps -a)
