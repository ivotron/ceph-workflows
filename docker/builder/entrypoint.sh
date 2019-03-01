#!/usr/bin/env bash
set -ex

if [ -z $CEPH_SRC_DIR ]; then
  echo "Expecting CEPH_SRC_DIR variable"
  exit 1
fi

cd $CEPH_SRC_DIR

if [ "$CEPH_GIT_CLEAN" == "true" ] ; then
  if [ -z "$CEPH_GIT_CLEAN_YES_I_MEAN_IT" ]; then
    echo "WARNING: Running with CEPH_GIT_CLEAN=1 will delete every untracked file"
    echo "         as well as discarding any uncommitted changes. If you are sure"
    echo "         you want to do this, run with CEPH_GIT_CLEAN_YES_I_MEAN_IT=1"
    exit 1
  fi
  if [ -z $CEPH_GIT_REF ]; then
    echo "Expecting CEPH_GIT_REF variable"
    exit 1
  fi
  git clean -dfx
  git submodule foreach 'git clean -dfx'

  git checkout $CEPH_GIT_REF
  git reset --hard
  git submodule foreach 'git reset --hard'

  cat <<EOF > ceph.conf
plugin dir = lib
erasure code dir = lib
EOF

fi

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
  cmake3 $CMAKE_INSTALL_PREFIX=/usr/local $CEPH_CMAKE_FLAGS ..
fi

make -j$CEPH_BUILD_THREADS $@

if [ "$CEPH_INSTALL_HEADERS" == "true" ] ; then
  mkdir --parents $INSTALL_DIR/usr/include/rados/
  cp -L $CEPH_SRC_DIR/src/include/rados/* $INSTALL_DIR/usr/include/rados/ || true
fi
