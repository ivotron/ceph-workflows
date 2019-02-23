# GHA for Ceph

Docker images to be used in github action workflows. Example (more 
available in `examples/`):

```hcl
workflow "build and deploy ceph" {
  resolves = "deploy"
}

action "build src" {
  uses = "docker://blkswanio/ceph-builder:mimic"
  args = "build"
  env = {
    CEPH_SRC_DIR = "./path/to/ceph/source"
    CEPH_GIT_REF = "v13.2.4"
  }
}

action "build image" {
  needs = "build src"
  uses = "docker://blkswanio/ceph-builder:mimic"
  args = "img"
  env = {
    CEPH_BASE_DAEMON_IMAGE = "ceph/daemon:master-b3fcb90-mimic-centos-7-x86_64"
    CEPH_IMAGE_NAME = "ivotron/myceph:exp"
  }
}

action "docker login" {
  needs = "build image"
  uses = "actions/docker/login@master"
  secrets = [
    "DOCKER_USERNAME",
    "DOCKER_PASSWORD"
  ]
}

action "docker push" {
  needs = "docker login"
  uses = "actions/docker/cli@master"
  args = "push ivotron/myceph:exp"
}
```

