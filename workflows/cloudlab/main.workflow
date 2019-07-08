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

action "download ceph-ansible" {
  needs = "allocate resources"
  uses = "veggiemonk/bin/git@master"
  args = [
    "clone", "--branch", "v3.2.18",
    "https://github.com/ceph/ceph-ansible",
    "workflows/cloudlab/ansible/ceph-ansible/"
  ]
}

action "install ceph-ansible requirements" {
  needs = ["download ceph-ansible"]
  uses = "jefftriplett/python-actions@master"
  args = "pip install -r workflows/cloudlab/ansible/ceph-ansible/requirements.txt"
}

action "deploy" {
  needs = ["install ceph-ansible requirements"]
  uses = "jefftriplett/python-actions@master"
  args = [
    "ansible-playbook", "-i", "workflows/cloudlab/geni/hosts",
    "workflows/cloudlab/ansible/playbook.yml"
  ]
  env {
    ANSIBLE_CONFIG = "workflows/cloudlab/ansible/ceph-ansible/ansible.cfg"
    ANSIBLE_SSH_CONTROL_PATH = "/dev/shm/cp%%h-%%p-%%r"
  }
  secrets = ["ANSIBLE_SSH_KEY_DATA"]
}

action "run benchmarks" {
  needs = "deploy"
  uses = "./actions/cbt"
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
