#!/usr/bin/env bash
set -ex

if [ "$1" == 'build' ]; then
  build-ceph
elif [ "$1" == 'img' ]; then
  generate-docker-image
else
  echo "Unknown argument '$1'"
  exit 1
fi
