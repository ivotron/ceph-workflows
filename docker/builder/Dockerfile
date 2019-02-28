FROM ubuntu:18.04

ARG CEPH_GIT_REPO="https://github.com/ceph/ceph"
ARG CEPH_GIT_REF="master"

RUN apt update && \
    apt install -y git && \
    git clone --branch $CEPH_GIT_REF --depth=1 $CEPH_GIT_REPO && \
    cd ceph/ && \
    ./install-deps.sh && \
    apt install ccache && \
    cd ../ && \
    rm -rf ceph/ && \
    apt autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD . /usr/bin/

ENTRYPOINT ["entrypoint.sh"]
