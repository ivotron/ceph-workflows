workflow "build docker images" {
  on = "push"
  resolves = "end"
}

action "build ceph-builder" {
  uses = "actions/docker/cli@master"
  args = "build -t blkswanio/ceph-builder:mimic ./docker/builder"
}

action "docker login" {
  uses = "actions/docker/login@master"
  secrets = [
    "DOCKER_USERNAME",
    "DOCKER_PASSWORD"
  ]
  needs = [
    "build ceph-builder"
  ]
}

action "docker push" {
  needs = "docker login"
  uses = "actions/docker/cli@master"
  args = "push blkswanio/ceph-builder:mimic"
}
