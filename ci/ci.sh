#!/bin/sh

WORK_DIR=`pwd`
BUILD_CACHE_DIR=$WORK_DIR/build-cache
BUNDLE_DIR=$WORK_DIR/bundle
PROJECT_CODE=$WORK_DIR/project-code
ASSETS_DIR=$WORK_DIR/assets
IMAGE_TAR_DIR=$WORK_DIR/project-image-tar

bundle_gems() {
  if [ -f $BUILD_CACHE_DIR/bundle/rubygems.tar.bz2 ]; then
    tar -xjf $BUILD_CACHE_DIR/bundle/rubygems.tar.bz2 -C $BUNDLE_DIR 2>/dev/null &
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null; do
      i=$(( (i+1) %4 ))
      printf "\r${spin:$i:1} extracting bundle cache"
      sleep .1
    done
    printf "\r\e[1;32m√\e[m extracting bundle cache"
    printf "\n\n"
  fi

  BUNDLE_PATH=$BUNDLE_DIR bundle install --gemfile=$PROJECT_CODE/Gemfile --jobs=4 --clean
}

compile_assets() {
  cd $PROJECT_CODE && BUNDLE_PATH=$BUNDLE_DIR RAILS_ENV=production ./bin/rails assets:precompile 2>/dev/null &
  pid=$! # Process Id of the previous running command
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1} compiling assets"
    sleep .1
  done
  printf "\r\e[1;32m√\e[m compiling assets"

  cp -pPR $PROJECT_CODE/public/assets/. $ASSETS_DIR
}

_start_docker() {
  rm -rf /var/lib/docker
  cp -pPR $WORK_DIR/docker /var/lib/docker
  . /docker-lib.sh
  start_docker
}

build_image() {
  _start_docker

  RUBY_IMAGE_DIR=$WORK_DIR/ruby-2.3.1-image
  docker load -i $RUBY_IMAGE_DIR/image -q
  docker tag "$(cat $RUBY_IMAGE_DIR/image-id)" "$(cat $RUBY_IMAGE_DIR/repository):$(cat $RUBY_IMAGE_DIR/tag)"

  # if [ -f $BUILD_CACHE_DIR/docker/image.tar.bz2 ]; then
  #   docker load -i $BUILD_CACHE_DIR/docker/image.tar.bz2 -q 2>/dev/null &
  #   pid=$!
  #   spin='-\|/'
  #   i=0
  #   while kill -0 $pid 2>/dev/null; do
  #     i=$(( (i+1) %4 ))
  #     printf "\r${spin:$i:1} importing cached image.tar.bz2"
  #     sleep .1
  #   done
  #   printf "\r\e[1;32m√\e[m importing cached image.tar.bz2"
  #   printf "\n\n"
  # fi

  cp -pPR $BUNDLE_DIR $PROJECT_CODE/bundle
  cp -pPR $WORK_DIR/assets $PROJECT_CODE/public/assets

  cp $PROJECT_CODE/ci/.dockerignore $PROJECT_CODE

  docker build -f $PROJECT_CODE/ci/Dockerfile -t jamgood96/rails5testapp:latest $PROJECT_CODE

  cp -pPR /var/lib/docker/* $WORK_DIR/docker
  rm -rf $WORK_DIR/docker/btrfs/subvolumes/*

  apk add btrfs-progs

  cd /var/lib/docker/btrfs/subvolumes
  for f in *
  do
    echo $f
    echo $WORK_DIR/docker/btrfs/subvolumes/$f
    btrfs subvolume snapshot $f $WORK_DIR/docker/btrfs/subvolumes$f
  done

  # mkdir -p $IMAGE_TAR_DIR

  # printf "\n"
  # docker save jamgood96/rails5testapp:latest $(docker history -q jamgood96/rails5testapp:latest | sed '/^<missing>$/ d') | BZIP=--fast bzip2 - > $IMAGE_TAR_DIR/image.tar.bz2 2>/dev/null &
  # pid=$!
  # spin='-\|/'
  # i=0
  # while kill -0 $pid 2>/dev/null; do
  #   i=$(( (i+1) %4 ))
  #   printf "\r${spin:$i:1} exporting image.tar.bz2"
  #   sleep .1
  # done
  # printf "\r\e[1;32m√\e[m exporting image.tar.bz2"
  #
  # printf "\n"
  # docker save jamgood96/rails5testapp:latest | BZIP=--fast bzip2 - > $IMAGE_TAR_DIR/image.smaller.tar.bz2 2>/dev/null &
  # pid=$!
  # spin='-\|/'
  # i=0
  # while kill -0 $pid 2>/dev/null; do
  #   i=$(( (i+1) %4 ))
  #   printf "\r${spin:$i:1} exporting image.smaller.tar.bz2"
  #   sleep .1
  # done
  # printf "\r\e[1;32m√\e[m exporting image.smaller.tar.bz2"
}

_cleanup_bundle() {
  mkdir -p $BUILD_CACHE_DIR/bundle
  BZIP=--fast tar -cjf $BUILD_CACHE_DIR/bundle/rubygems.tar.bz2 -C $BUNDLE_DIR .
}

_cleanup_image() {
  mkdir -p $BUILD_CACHE_DIR/docker
  cp $IMAGE_TAR_DIR/image.tar.bz2 $BUILD_CACHE_DIR/docker/image.tar.bz2
}

cleanup() {
  echo CLEANING
  _cleanup_bundle
  _cleanup_image
}

cucumber() {
  _start_docker

  time docker load -i $IMAGE_TAR_DIR/image.smaller.tar.bz2 -q

  return 0
}

rspec() {
  echo `pwd`
  # _start_docker
  #
  # time docker load -i $IMAGE_TAR_DIR/image.tar.bz2 -q
  #
  # docker run --rm jamgood96/rails5testapp bundle exec rspec
}

"$@"
