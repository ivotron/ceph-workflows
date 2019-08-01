workflow "packet" {
  on = "push"
  resolves = ["terraform apply"]
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