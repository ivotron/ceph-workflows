workflow "cbt" {
  resolves = "run benchmarks"
}

action "install jinja2-cli" {
  uses = "jefftriplett/python-actions@master"
  args = "pip install jinja2-cli[yaml]"
}

action "generate cbt config" {
  needs = ["deploy"],
  uses = "jefftriplett/python-actions@master"
  args = [
    "jinja2",
    "--format=yaml",
    "--outfile", "test/cbt/config.yml",
    "test/cbt/config.yml.j2",
    "test/cbt/hosts.yaml"
  ]
}

# The cluster fsid is hardcoded and arbitrarily selected, so it does
# not change across multiple executions of the workflow
action "run benchmarks" {
  needs = ["generate cbt config"]
  uses = "./test/cbt/action"
  args = [
    "--archive", "./test/cbt/",
    "--conf", "./test/cbt/ansible/fetch/3eca8d23-12a7-40e0-b723-421e9b527959/etc/ceph/ceph.conf",
    "test/cbt/config.yml"
  ]
  env = {
    PDSH_SSH_ARGS_APPEND = "-o StrictHostKeyChecking=no"
  }
  secrets = ["PDSH_SSH_KEY_DATA"]
}
