workflow "radosbench on cloudlab" {
  on = "push"
  resolves = "teardown"
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
  uses = "popperized/geni/exec@master"
  args = "one-baremetal-node.py"
  secrets = ["GENI_KEY_PASSPHRASE"]
}

action "teardown" {
  uses = "popperized/geni/exec@master"
  args = "release.py"
  secrets = ["GENI_KEY_PASSPHRASE"]
}
