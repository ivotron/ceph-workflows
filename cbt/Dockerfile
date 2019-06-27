FROM python:2.7-slim-stretch

LABEL "com.github.actions.name"="CBT"
LABEL "com.github.actions.description"="Ceph Benchmarking Toolkit"
LABEL "com.github.actions.icon"="mic"
LABEL "com.github.actions.color"="blue"

LABEL "repository"="http://github.com/popperized/ceph/"
LABEL "homepage"="http://github.com/systemslab/popper"
LABEL "maintainer"="Ivo Jimenez <ivo@cs.ucsc.edu>"

ENV CEPH_CBT_VERSION=master
ENV DEBIAN_FRONTEND=noneinteractive

RUN apt update && \
    apt install -y git pdsh && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    pip install lxml pyyaml && \
    git clone --depth 1 --branch $CEPH_CBT_VERSION https://github.com/ceph/cbt /cbt

ADD entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
