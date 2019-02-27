#!/usr/bin/env bash
set -ex

if [ -z $CEPH_SRC_DIR ]; then
  echo "Expecting CEPH_SRC_DIR variable"
  exit 1
fi
if [ -z "$CEPH_IMAGE_NAME" ] ; then
  echo "ERROR: expecting CEPH_IMAGE variable"
  exit 1
fi
if [ -z "$CEPH_BASE_DAEMON_IMAGE" ] ; then
  echo "ERROR: expecting CEPH_BASE_IMAGE variable"
  exit 1
fi
if [ ! -d "$CEPH_SRC_DIR" ]; then
  echo "Expecting CEPH_SRC_DIR variable"
  exit 1
fi
if [ ! -d "$GITHUB_WORKSPACE/$CEPH_SRC_DIR" ]; then
  echo "Expecting CEPH_SRC_DIR at $GITHUB_WORKSPACE"
  exit 1
fi

INSTALL_DIR=$GITHUB_WORKSPACE/$CEPH_SRC_DIR/build/bin

if [ -z "$(ls -A $INSTALL_DIR)" ]; then
  echo "Looks like $INSTALL_DIR is empty."
  exit 1
fi

docker pull $CEPH_BASE_DAEMON_IMAGE

docker rm cephbase || true
docker run \
  --name cephbase \
  --entrypoint=/bin/bash \
  --volume $INSTALL_DIR:$INSTALL_DIR
  $CEPH_BASE_DAEMON_IMAGE -c "cp $INSTALL_DIR/* /usr/bin/"
docker commit --change='ENTRYPOINT ["/entrypoint.sh"]' cephbase $CEPH_IMAGE_NAME &> /dev/null
docker rm cephbase || true

echo "created image $CEPH_IMAGE_NAME"
