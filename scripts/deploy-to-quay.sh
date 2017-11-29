#!/usr/bin/env bash

APP_DIR=/usr/src/app
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
IMG_TAG_PREFIX=branch--
IMG_TAG=$IMG_TAG_PREFIX$GIT_BRANCH
IMG_REPO=navocat-collector
WORKING_DIR=$PWD

IMG_TAG=${CUSTOM_TAG:-$IMG_TAG}

function buildImage() {
  echo "building image..."
  docker build -t quay.io/medullanmps/$IMG_REPO:$IMG_TAG .
}

function uploadImage() {
  echo "attempting to pushing image to Quay..."
  docker push quay.io/medullanmps/$IMG_REPO:$IMG_TAG

  # $? contains the exit code of the previous command
  if [ $? != 0 ]; then
    echo "failed to upload image: quay.io/medullanmps/$IMG_REPO:$IMG_TAG to Quay"
  fi
}

buildImage

uploadImage

