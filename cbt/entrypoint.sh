#!/bin/bash
set -e

if [ -z "CBT_ARCHIVE_DIR" ]; then
  echo "Setting CBT_ARCHIVE_DIR=./archive/"
  mkdir -p ./archive
  CBT_ARCHIVE_DIR="./archive"
fi

if [ -z "CBT_CEPH_CONF" ]; then
  echo "Expecting CBT_CEPH_CONF variable"
  exit 1
fi

if [ -z "CBT_CONF" ]; then
  echo "Expecting CBT_CONF variable"
  exit 1
fi

/root/cbt.py \
  --archive="$CBT_ARCHIVE_DIR" \
  --conf="$CBT_CEPH_CONF" \
  "$CBT_CONF"
