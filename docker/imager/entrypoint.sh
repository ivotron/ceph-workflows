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
if [ -z "$CEPH_BUILDER_IMAGE" ] ; then
  echo "ERROR: expecting CEPH_BUILDER_IMAGE variable"
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

# download daemon scripts
mkdir -p $INSTALL_DIR/daemon
docker pull ceph/daemon:latest-bis-master
docker run --rm \
  --entrypoint=/bin/bash \
  --volume $INSTALL_DIR:$INSTALL_DIR \
  ceph/daemon:latest-bis-master \
    -c "cp -r /opt/ceph-container/bin/* $INSTALL_DIR/daemon/"

# ensure we have the builder image at the right version
docker pull $CEPH_BUILDER_IMAGE

# remove in case it was left from a previous execution
docker rm cephbase || true

# copy built files into a new instance of the base image
docker run \
  --name cephbase \
  --entrypoint=/bin/bash \
  --volume $INSTALL_DIR:$INSTALL_DIR \
  $CEPH_BUILDER_IMAGE \
    -c "cp -r $INSTALL_DIR/bin/* /usr/local/bin/ && \
        cp -r $INSTALL_DIR/lib/* /usr/local/lib/ && \
        mkdir -p /opt/ceph-container/bin && \
        cp -r $INSTALL_DIR/daemon/* /opt/ceph-container/bin/ && \
        echo 'PATH=\$PATH:/opt/ceph-container/bin' > /etc/environment"

# commit the above change so that we obtain a new image
docker commit \
  --change='ENTRYPOINT ["/opt/ceph-container/bin/entrypoint.sh"]' \
  cephbase $CEPH_OUTPUT_IMAGE

# cleanup
docker rm cephbase

echo "created image $CEPH_OUTPUT_IMAGE"
