workflow "build docker images" {
  resolves = "end"
}

action "build builder" {
  uses = "actions/docker/cli@master"
  args = "build --build-arg CEPH_GIT_REF=nautilus -t popperized/ceph-builder:nautilus ./builder/docker"
}

action "docker login" {
  uses = "actions/docker/login@master"
  secrets = [
    "DOCKER_USERNAME",
    "DOCKER_PASSWORD"
  ]
  needs = [
    "build builder"
  ]
}

action "push builder" {
  needs = "docker login"
  uses = "actions/docker/cli@master"
  args = "push popperized/ceph-builder:nautilus"
}

action "end" {
  needs = [
    "push builder"
  ]
  uses = "actions/docker/cli@master"
  args = "version"
}
