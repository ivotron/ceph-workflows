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

SRC_DIR=$GITHUB_WORKSPACE/$CEPH_SRC_DIR
BUILD_DIR=$SRC_DIR/build

if [ -z "$(ls -A $BUILD_DIR/bin)" ]; then
  echo "Looks like $BUILD_DIR is empty. Have you compiled yet?"
  exit 1
fi

# download daemon scripts
mkdir -p $BUILD_DIR/daemon
docker pull ceph/daemon:latest-bis-master
docker run --rm \
  --entrypoint=/bin/bash \
  --volume $BUILD_DIR:$BUILD_DIR \
  ceph/daemon:latest-bis-master \
    -c "cp -r /opt/ceph-container/bin/* $BUILD_DIR/daemon/"

# ensure we have the builder image at the right version
docker pull $CEPH_BUILDER_IMAGE

# remove in case it was left from a previous execution
docker rm cephbase || true

# copy built files into a new instance of the base image
docker run \
  --name cephbase \
  --entrypoint=/bin/bash \
  --volume $SRC_DIR:$SRC_DIR \
  $CEPH_BUILDER_IMAGE -c \
    "rm -f /usr/bin/entrypoint.sh && \
     export PYTHONPATH=/usr/lib/python2.7/site-packages/ && \
     make -C $BUILD_DIR install && \
     mkdir -p /opt/ceph-container/bin /etc/ceph && \
     cp -r $BUILD_DIR/daemon/* /opt/ceph-container/bin/ && \
     sed -i 's/bootstrap_mgr//' /opt/ceph-container/bin/demo.sh && \
     sed -i 's/# the mgr is.*/bootstrap_mgr/' /opt/ceph-container/bin/demo.sh && \
     echo '#!/usr/bin/env bash' > new_entrypoint.sh && \
     echo 'export PATH=\$PATH:/opt/ceph-container/bin' >> new_entrypoint.sh && \
     echo 'export PYTHONPATH=/usr/lib/python2.7/site-packages/' >> new_entrypoint.sh && \
     echo 'source /opt/ceph-container/bin/entrypoint.sh' >> new_entrypoint.sh && \
     chmod +x new_entrypoint.sh && \
     mv new_entrypoint.sh /usr/bin && \
     ldconfig && \
     useradd -r -s /usr/sbin/nologin ceph"

# commit the above change so that we obtain a new image
docker commit \
  --change='ENTRYPOINT ["new_entrypoint.sh"]' \
  cephbase $CEPH_OUTPUT_IMAGE

# cleanup
docker rm cephbase

echo "created image $CEPH_OUTPUT_IMAGE"
