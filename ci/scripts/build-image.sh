#!/bin/sh

. /docker-lib.sh

start_docker

docker run --rm -v "$PWD":/worker -w /worker iron/ruby:dev sh -c 'bundle config --local build.nokogiri --use-system-libraries && bundle install --standalone --clean'

docker build . taco_tuesday

echo $(docker ps -a)
