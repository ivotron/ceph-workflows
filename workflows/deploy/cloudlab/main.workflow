workflow "cloudlab" {
  resolves = "deploy"
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
  args = ["workflows/deploy/cloudlab/geni/config.py", "apply"]
  secrets = ["GENI_KEY_PASSPHRASE"]
}

action "generate ansible inventory" {
  needs = "allocate resources"
  uses = "popperized/geni/exec@master"
  args = ["workflows/deploy/cloudlab/geni/config.py", "manifest-to-inventory"]
}

action "download ceph-ansible" {
  needs = "generate ansible inventory"
  uses = "popperized/git@master"
  runs = [
    "sh", "-c",
    "cd workflows/deploy/cloudlab/ansible && (git -C ceph-ansible/ fetch || git clone --branch v3.2.18 https://github.com/ceph/ceph-ansible)"
  ]
}

action "deploy" {
  needs = "download ceph-ansible"
  uses = "popperized/ansible@v2.6"
  args = [
    "-i", "workflows/deploy/cloudlab/geni/hosts.yaml",
    "workflows/deploy/cloudlab/ansible/playbook.yml"
  ]
  env {
    ANSIBLE_PIP_FILE = "workflows/deploy/cloudlab/ansible/ceph-ansible/requirements.txt"
    ANSIBLE_CONFIG = "workflows/deploy/cloudlab/ansible/ceph-ansible/ansible.cfg"
    ANSIBLE_SSH_CONTROL_PATH = "/dev/shm/cp%%h-%%p-%%r"
    ANSIBLE_LOG_PATH = "workflows/deploy/cloudlab/ansible/ansible.log"
  }
  secrets = ["ANSIBLE_SSH_KEY_DATA"]
}

## run this action at the end to release allocated resources
#action "teardown" {
#  needs = "<NAME OF PREVIOUS ACTION>"
#  uses = "popperized/geni/exec@master"
#  args = ["workflows/deploy/cloudlab/geni/config.py", "destroy"]
#  secrets = ["GENI_KEY_PASSPHRASE"]
#}
