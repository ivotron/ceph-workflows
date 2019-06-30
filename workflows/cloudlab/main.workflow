workflow "radosbench on cloudlab" {
  on = "push"
  resolves = "validate results"
}

action "build context" {
  uses = "popperized/geni/build-context@master"
  env = {
    GENI_FRAMEWORK = "cloudlab"
  }
  secrets = [
    "GENI_PROJECT",
    "GENI_USERNAME",
    "GENI_PASSWORD",
    "GENI_PUBKEY_DATA",
    "GENI_CERT_DATA"
  ]
}

action "allocate resources" {
  needs = "build context"
  uses = "popperized/geni/exec@master"
  args = "workflows/cloudlab/geni/request.py"
  secrets = ["GENI_KEY_PASSPHRASE"]
}

#action "build packages" {
#  uses = "popperized/deb@master"
#  env = {
#    DEB_PROJECT_DIR = "ceph/"
#    DEB_INSTALL_DEPS_SCRIPT = "scripts/install_deps.sh",
#  }
#}

action "deploy ceph" {
  needs = ["allocate resources"]
  uses = "popperized/ansible@master"
  args = [
    "-i", "workflows/cloudlab/geni/hosts",
    "workflows/cloudlab/ansible/playbook.yml"
  ]
  env {
    ANSIBLE_GALAXY_FILE = "workflows/cloudlab/ansible/requirements.yml"
    ANSIBLE_HOST_KEY_CHECKING = "False"
  }
  secrets = ["ANSIBLE_SSH_KEY_DATA"]
}

action "run benchmarks" {
  needs = "deploy ceph"
  uses = "./cbt"
  args = [
    "--archive", "workflows/cloudlab/results/",
    "--conf", "workflows/cloudlab/cbt/conf.yml"
  ]
  env = {
    PDSH_SSH_ARGS_APPEND = "-o StrictHostKeyChecking=no"
  }
}

action "teardown" {
  needs = "run benchmarks"
  uses = "popperized/geni/exec@master"
  args = "workflows/cloudlab/geni/release.py"
  secrets = ["GENI_KEY_PASSPHRASE"]
}

action "plot results" {
  needs = "teardown"
  uses = "sh"
  args = "ls"
}

action "validate results" {
  needs = "plot results"
  uses = "sh"
  runs = "ls"
}
