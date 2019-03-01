workflow "build docker images" {
  resolves = "end"
}

action "build builder" {
  uses = "actions/docker/cli@master"
  args = "build --build-arg CEPH_GIT_REF=nautilus -t blkswanio/ceph-builder:nautilus ./docker/builder"
}

action "build imager" {
  uses = "actions/docker/cli@master"
  args = "build -t blkswanio/ceph-imager:latest ./docker/imager"
}

action "docker login" {
  uses = "actions/docker/login@master"
  secrets = [
    "DOCKER_USERNAME",
    "DOCKER_PASSWORD"
  ]
  needs = [
    "build builder",
    "build imager"
  ]
}

action "push builder" {
  needs = "docker login"
  uses = "actions/docker/cli@master"
  args = "push blkswanio/ceph-builder:mimic"
}

action "push imager" {
  needs = "docker login"
  uses = "actions/docker/cli@master"
  args = "push blkswanio/ceph-imager:latest"
}

action "end" {
  needs = [
    "push builder",
    "push imager"
  ]
  uses = "actions/docker/cli@master"
  args = "version"
}
