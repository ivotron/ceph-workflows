workflow "build docker images" {
  on = "push"
  resolves = "end"
}

action "build builder" {
  uses = "actions/docker/cli@master"
  args = "build -t blkswanio/ceph-builder:mimic ./docker/builder"
}

action "build imager" {
  uses = "actions/docker/cli@master"
  args = "build -t blkswanio/ceph-imager:latest ./docker/imager"
}

action "build ceph-ansible" {
  uses = "actions/docker/cli@master"
  args = "build -t blkswanio/ceph-ansible:v3.2.7 ./docker/ansible"
}

action "docker login" {
  uses = "actions/docker/login@master"
  secrets = [
    "DOCKER_USERNAME",
    "DOCKER_PASSWORD"
  ]
  needs = [
    "build builder",
    "build imager",
    "build ceph-ansible"
  ]
}

action "push ceph-builder" {
  needs = "docker login"
  uses = "actions/docker/cli@master"
  args = "push blkswanio/ceph-builder:mimic"
}

action "push ceph-ansible" {
  needs = "docker login"
  uses = "actions/docker/cli@master"
  args = "push blkswanio/ceph-ansible:v3.2.7"
}

action "end" {
  needs = [
    "push ceph-builder"
    "push ceph-ansible"
  ]
  uses = "actions/docker/cli@master"
  args = "version"
}
