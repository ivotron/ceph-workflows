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

function create_image {
  BASE_IMAGE=$1
  OUTPUT_IMAGE=$2
  BASE_PATH=$3
  TARGET_PATH=$4
  SKIP_IF_EMPTY_DELTA=$5

  delta_bin="$(rsync -ani --omit-dir-times --exclude=base --out-format='%n' $BASE_PATH/bin $PATH_2/bin)"
  delta_lib="$(rsync -ani --omit-dir-times --exclude=base --out-format='%n' $BASE_PATH/lib $PATH_2/lib)"

  # get the delta
  if [ -z "$SKIP_IF_EMPTY_DELTA" ] && [ -z "$delta_bin" ] && [ -z "$delta_lib" ]; then
    echo "No new bin/ or lib/ files found. Not creating image."
    exit 0
  fi

  # remove in case it was left from a previous execution
  docker rm cephbase || true

  # copy built files into a new instance of the base image
  docker run \
    --name cephbase \
    --entrypoint=/bin/bash \
    --volume $TARGET_PATH:$TARGET_PATH \
    $BASE_IMAGE \
      -c "cd $TARGET_PATH && cp $delta_bin /usr/bin/ && cp -r --parents $delta_lib /usr/lib/"

  # commit the above change so that we obtain a new image
  docker commit \
    --change='ENTRYPOINT ["/opt/ceph-container/bin/entrypoint.sh"]' \
    cephbase $OUTPUT_IMAGE

  # cleanup
  docker rm cephbase

  # clear the delta by make the base and target even
  cp $delta_bin $BASE_PATH/bin/
  cp $delta_lib $BASE_PATH/lib/
}

INSTALL_DIR=$GITHUB_WORKSPACE/$CEPH_SRC_DIR/build/

if [ -z "$(ls -A $INSTALL_DIR/bin)" ]; then
  echo "Looks like $INSTALL_DIR is empty. Have you compiled yet?"
  exit 1
fi

docker pull $CEPH_BASE_DAEMON_IMAGE

# create base image and directory for obtaining deltas
if [ ! -d $INSTALL_DIR/base ] || [ "$CEPH_REBUILD_BASE" == "true" ] ; then
  rm -rf $INSTALL_DIR/base

  mkdir -p $INSTALL_DIR/base/bin  $INSTALL_DIR/base/lib

  create_image \
    $CEPH_BASE_DAEMON_IMAGE \
    $CEPH_OUTPUT_IMAGE-base \
    $INSTALL_DIR/ \
    $INSTALL_DIR/base/

  # tag the image and we're done
  docker tag $CEPH_OUTPUT_IMAGE-base $CEPH_OUTPUT_IMAGE

  exit 0
fi

create_image \
  $CEPH_OUTPUT_IMAGE-base \
  $CEPH_OUTPUT_IMAGE \
  $INSTALL_DIR/base/ \
  $INSTALL_DIR/ \
  "skip-if-empty-delta"

echo "created image $CEPH_OUTPUT_IMAGE"
