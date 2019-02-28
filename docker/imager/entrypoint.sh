#!/usr/bin/env bash
set -ex

if [ -z $CEPH_SRC_DIR ]; then
  echo "Expecting CEPH_SRC_DIR variable"
  exit 1
fi
if [ -z "$CEPH_OUTPUT_IMAGE" ] ; then
  echo "ERROR: expecting CEPH_IMAGE variable"
  exit 1
fi
if [ -z "$CEPH_BASE_DAEMON_IMAGE" ] ; then
  echo "ERROR: expecting CEPH_BASE_DAEMON_IMAGE variable"
  exit 1
fi
if [ ! -d "$GITHUB_WORKSPACE/$CEPH_SRC_DIR" ]; then
  echo "Expecting CEPH_SRC_DIR at $GITHUB_WORKSPACE"
  exit 1
fi

INSTALL_DIR=$GITHUB_WORKSPACE/$CEPH_SRC_DIR/build/

if [ -z "$(ls -A $INSTALL_DIR/bin)" ]; then
  echo "Looks like $INSTALL_DIR is empty. Have you compiled yet?"
  exit 1
fi

docker pull $CEPH_BASE_DAEMON_IMAGE

# remove in case it was left from a previous execution
docker rm cephbase || true

# copy built files into a new instance of the base image
docker run \
  --name cephbase \
  --entrypoint=/bin/bash \
  --volume $INSTALL_DIR:$INSTALL_DIR \
  $CEPH_BASE_DAEMON_IMAGE \
    -c "cp -r $INSTALL_DIR/bin/* /usr/bin/ && cp -r $INSTALL_DIR/lib/* /usr/lib/"

# commit the above change so that we obtain a new image
docker commit \
  --change='ENTRYPOINT ["/opt/ceph-container/bin/entrypoint.sh"]' \
  cephbase $CEPH_OUTPUT_IMAGE

# cleanup
docker rm cephbase

echo "created image $CEPH_OUTPUT_IMAGE"
