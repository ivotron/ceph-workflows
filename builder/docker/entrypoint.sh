#!/usr/bin/env bash
set -ex

if [ -z $CEPH_SRC_DIR ]; then
  echo "Expecting CEPH_SRC_DIR variable"
  exit 1
fi

cd $CEPH_SRC_DIR

if [ "$CEPH_CMAKE_CLEAN" == "true" ]; then
  rm -rf build/
fi

git submodule update --init --recursive

if [ -z "$CEPH_BUILD_THREADS" ] ; then
  CEPH_BUILD_THREADS=`grep processor /proc/cpuinfo | wc -l`
fi

mkdir -p build
cd build
if [ -z "$(ls -A ./)" ] || [ "$CEPH_CMAKE_RECONFIGURE" == "true" ] ; then
  cmake -DCMAKE_INSTALL_PREFIX=/usr -DWITH_CCACHE=ON $CEPH_CMAKE_FLAGS ..
fi

make -j$CEPH_BUILD_THREADS $@

if [ -n "$CEPH_OUTPUT_DOCKER_IMAGE" ]; then
  generate-daemon-image
fi
