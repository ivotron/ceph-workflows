workflow "radosbench on cloudlab" {
  resolves = "validate results"
}

action "install jinja2-cli" {
  uses = "jefftriplett/python-actions@master"
  args = "pip install jinja2-cli[yaml]"
}

action "download ceph-ansible" {
  uses = "popperized/git@master"
  runs = [
    "sh", "-c",
    "cd workflows/cloudlab/ansible && (git -C ceph-ansible/ fetch || git clone --branch v3.2.18 https://github.com/ceph/ceph-ansible)"
  ]
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
  needs = ["build context", "download ceph-ansible", "install jinja2-cli"]
  uses = "popperized/geni/exec@master"
  args = ["workflows/cloudlab/geni/config.py", "apply"]
  secrets = ["GENI_KEY_PASSPHRASE"]
}

action "generate ansible inventory" {
  needs = "allocate resources"
  uses = "popperized/geni/exec@master"
  args = ["workflows/cloudlab/geni/config.py", "manifest-to-inventory"]
}

action "deploy" {
  needs = "generate ansible inventory", 
  uses = "popperized/ansible@v2.6"
  args = [
    "-i", "workflows/cloudlab/geni/hosts.yaml",
    "workflows/cloudlab/ansible/playbook.yml"
  ]
  env {
    ANSIBLE_PIP_FILE = "workflows/cloudlab/ansible/ceph-ansible/requirements.txt"
    ANSIBLE_CONFIG = "workflows/cloudlab/ansible/ceph-ansible/ansible.cfg"
    ANSIBLE_SSH_CONTROL_PATH = "/dev/shm/cp%%h-%%p-%%r"
    ANSIBLE_LOG_PATH = "workflows/cloudlab/ansible/ansible.log"
  }
  secrets = ["ANSIBLE_SSH_KEY_DATA"]
}

action "generate cbt config" {
  needs = ["deploy"],
  uses = "jefftriplett/python-actions@master"
  args = [
    "jinja2",
    "--format=yaml",
    "--outfile", "workflows/cloudlab/cbt/config.yml",
    "workflows/cloudlab/cbt/config.yml.j2",
    "workflows/cloudlab/geni/hosts.yaml"
  ]
}

# The cluster fsid is hardcoded and arbitrarily selected, so it does
# not change across multiple executions of the workflow
action "run benchmarks" {
  needs = ["generate cbt config"]
  uses = "./actions/cbt"
  args = [
    "--archive", "./workflows/cloudlab/",
    "--conf", "./workflows/cloudlab/ansible/fetch/3eca8d23-12a7-40e0-b723-421e9b527959/etc/ceph/ceph.conf",
    "workflows/cloudlab/cbt/config.yml"
  ]
  env = {
    PDSH_SSH_ARGS_APPEND = "-o StrictHostKeyChecking=no"
  }
  secrets = ["PDSH_SSH_KEY_DATA"]
}

action "teardown" {
  needs = "run benchmarks"
  uses = "popperized/geni/exec@master"
  args = ["workflows/cloudlab/geni/config.py", "destroy"]
  secrets = ["GENI_KEY_PASSPHRASE"]
}

action "plot results" {
  needs = "teardown"
  uses = "sh"
  args = "ls"
}

action "validate results" {
  needs = ["plot results"]
  uses = "sh"
  runs = "ls"
}
