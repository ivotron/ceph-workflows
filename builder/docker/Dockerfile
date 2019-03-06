FROM ubuntu:18.04

ARG CEPH_GIT_REPO="https://github.com/ceph/ceph"
ARG CEPH_BUILDER_IMAGE_NAME="popperized/ceph-builder"
ARG CEPH_GIT_REF="master"

RUN apt update && \
    apt install -y git docker.io && \
    git clone --branch $CEPH_GIT_REF --depth=1 $CEPH_GIT_REPO && \
    cd ceph/ && \
    ./install-deps.sh && \
    apt install -y ccache python-prettytable python-requests && \
    cd ../ && \
    rm -rf ceph/ && \
    apt autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo ${CEPH_BUILDER_IMAGE_NAME}:${CEPH_GIT_REF} > /builder-image

ADD . /usr/bin/

ENTRYPOINT ["entrypoint.sh"]
