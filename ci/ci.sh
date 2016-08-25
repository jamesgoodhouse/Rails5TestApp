#!/bin/sh

WORK_DIR=`pwd`

ASSETS_DIR=$WORK_DIR/assets
BUILD_CACHE_DIR=$WORK_DIR/build-cache
BUNDLE_DIR=$WORK_DIR/bundle
GIT_REPO_DIR=$WORK_DIR/git-repo
IMAGE_CACHE_DIR=$WORK_DIR/image-cache

IMAGE_REPO=registry.docker-playground.pdx.renewfund.com:80/rails5testapp
IMAGE_TAG=latest
IMAGE=$IMAGE_REPO:$IMAGE_TAG

_spinner() {
  pid=$!; spin='-\|/'; i=0

  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1} $1"
    sleep .1
  done

  printf "\r\e[1;32m√\e[m $1\n\n"
}

_extract_cache() {
  if [ -f $BUILD_CACHE_DIR/$1.tar.gz ]; then
    tar -xzf $BUILD_CACHE_DIR/$1.tar.gz -C $2 2>/dev/null &
    _spinner "extracting $1 cache"
  fi
}

_cache_bundle() {
  tar -czf $WORK_DIR/bundle-tar/bundle.tar.gz -C $BUNDLE_DIR .
}

_start_docker() {
  . /docker-lib.sh
  start_docker "registry.docker-playground.pdx.renewfund.com:80"
}

_load_image() {
  gunzip -c $IMAGE_CACHE_DIR/image.tar.gz | docker load &>/dev/null &
  _spinner "loading cached image from previous build"
}

_prepare_image() {
  cp -pPR $BUNDLE_DIR $GIT_REPO_DIR/bundle
  cp -pPR $ASSETS_DIR $GIT_REPO_DIR/public/assets
  cp $GIT_REPO_DIR/ci/.dockerignore $GIT_REPO_DIR
}

_cache_image() {
  image_ids=$(docker history -q $IMAGE | sed '/^<missing>$/ d')
  docker save $IMAGE $(echo $image_ids) | gzip -c > $WORK_DIR/image-tar/image.tar.gz 2>/dev/null &
  printf "\n"
  _spinner "caching image for later builds"
}

bundle_gems() {
  _extract_cache bundle $BUNDLE_DIR
  BUNDLE_PATH=$BUNDLE_DIR bundle install --gemfile=$GIT_REPO_DIR/Gemfile --clean
  _cache_bundle
}

compile_assets() {
  ln -s $ASSETS_DIR $GIT_REPO_DIR/public/assets && cd $GIT_REPO_DIR
  regex="s|^.\+\(Writing \)$GIT_REPO_DIR/\(.\+\)$|\1\2|"
  BUNDLE_PATH=$BUNDLE_DIR RAILS_ENV=production bundle exec rake assets:precompile 2>&1 | sed "$regex"
  mv $GIT_REPO_DIR/public/assets/* $ASSETS_DIR
  printf "\e[1;32mAsset compilation complete!\e[m"
}

build_image() {
  _start_docker
  docker pull 
  if [ -f $IMAGE_CACHE_DIR/image.tar.gz ]; then _load_image; fi
  _prepare_image
  docker build -f $GIT_REPO_DIR/ci/Dockerfile -t $IMAGE $GIT_REPO_DIR
  _cache_image
}

rspec() {
  _start_docker
  _load_image
  docker run --rm $IMAGE bundle exec rspec
}

cucumber() {
  _start_docker
  _load_image
  docker run --rm $IMAGE bundle exec rspec
}

regex="^$@ is a \(shell \)\{0,1\}function$"
if [ -n "$(type -t $@)" ] && echo "$(type $@)" | grep -q "$regex"; then
  if echo "$@" | grep -q '^_'; then
    echo not allowed
  else
    "$@"
  fi
else
  echo $@ not function
fi
