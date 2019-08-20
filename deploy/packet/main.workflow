workflow "packet" {
  on = "push"
  resolves = "deploy"
}

action "terraform init" {
  uses = "innovationnorway/github-action-terraform@master"
  args=["init", "./deploy/packet/terraform"]
  env = {
    TF_ACTION_WORKING_DIR = "./deploy/packet/terraform"
    TF_ACTION_COMMENT = "false"
  }
  secrets = ["TF_VAR_PACKET_API_KEY"]
}
action "terraform plan" {
  uses = "innovationnorway/github-action-terraform@master"
  needs = ["terraform init"]
  args=["plan","-out=tfplan","./deploy/packet/terraform"]
  env = {
    TF_ACTION_WORKING_DIR = "./deploy/packet/terraform"
    TF_ACTION_COMMENT = "false"
  }
  secrets = ["TF_VAR_PACKET_API_KEY"]
}

action "terraform apply" {
  needs = ["terraform plan"]
  uses = "innovationnorway/github-action-terraform@master"
  secrets = ["TF_VAR_PACKET_API_KEY"]
  args=["apply", "-auto-approve", "./tfplan"]
  env = {
    TF_ACTION_WORKING_DIR = "./deploy/packet/terraform"
    TF_ACTION_WORKSPACE = "default"
    TF_ACTION_COMMENT = "false"
  }
}

action "download ceph-ansible" {
  needs = "terraform apply"
  uses = "popperized/git@master"
  runs = [
    "sh", "-c",
    "cd deploy/ && (git -C ceph-ansible/ fetch || git clone --branch v3.2.18 https://github.com/ceph/ceph-ansible)"
  ]
}

action "deploy" {
  needs = "download ceph-ansible"
  uses = "popperized/ansible@v2.6"
  args = [
    "-i", "deploy/packet/hosts.yaml",
    "deploy/packet/ansible/playbook.yml"
  ]
  env {
    ANSIBLE_PIP_FILE = "deploy/ceph-ansible/requirements.txt"
    ANSIBLE_CONFIG = "deploy/ceph-ansible/ansible.cfg"
    ANSIBLE_SSH_CONTROL_PATH = "/dev/shm/cp%%h-%%p-%%r"
    ANSIBLE_LOG_PATH = "deploy/packet/ansible/ansible.log"
  }
  secrets = ["ANSIBLE_SSH_KEY_DATA"]
}

## run this action at the end to release allocated resources
#action "teardown" {
#  needs = "<NAME OF PREVIOUS ACTION>"
#  uses = "innovationnorway/github-action-terraform@master"
#  args = ["destroy",
#            "-auto-approve",
#            "./deploy/packet/terraform"]
#  secrets = ["TF_VAR_PACKET_API_KEY"]
#}