FROM centos:7.6.1810

ARG CEPH_GIT_REPO="https://github.com/ceph/ceph"
ARG CEPH_GIT_REF="mimic"

# update gcc
RUN yum install -y centos-release-scl-rh && \
    INSTALL_PKGS="devtoolset-7-gcc devtoolset-7-gcc-c++ devtoolset-7-gcc-gfortran devtoolset-7-gdb" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all -y

ENV PATH=/opt/rh/devtoolset-7/root/usr/bin/:$PATH

# install ceph build dependencies
RUN yum install -y git bc python-pip && \
    git clone --branch $CEPH_GIT_REF --depth=1 $CEPH_GIT_REPO && \
    cd ceph/ && \
    ./install-deps.sh && \
    yum erase -y cmake && \
    yum install -y cmake3 && \
    yum clean all -y && \
    cd ../ && \
    rm -rf ceph/

ADD . /usr/bin/

ENTRYPOINT ["entrypoint.sh"]
