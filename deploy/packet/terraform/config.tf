variable "PACKET_API_KEY" {}
variable "OSD_COUNT" { default = 1 }
provider "packet" {
  auth_token = "${var.PACKET_API_KEY}"
}

locals {
  project_id = "ead345e7-4525-4d09-bf49-c8b2b6e0f9cf"
}

resource "packet_device" "monitor" {
  hostname="monitor"
  project_id       = "${local.project_id}"
  operating_system = "ubuntu_18_04"
  plan = "t1.small.x86"
  billing_cycle    = "hourly"
  facilities = ["ewr1"]
  provisioner "local-exec" {
    command = <<EOT
cat <<EOF >  ./deploy/packet/ansible/hosts.yml
all:
    children:
        monitor:
            ${self.access_public_ipv4}
        osds:
EOT

  }
}

resource "packet_device" "osd" {
  count = "${var.OSD_COUNT}"
  hostname="osd.${count.index}"
  project_id       = "${local.project_id}"
  operating_system = "ubuntu_18_04"
  plan = "t1.small.x86"
  billing_cycle    = "hourly"
  facilities = ["ewr1"]
  provisioner "local-exec" {
    command = <<EOT
    sleep ${count.index+5}s && \
    cat <<EOF >> ./deploy/packet/ansible/hosts.yml
            ${self.access_public_ipv4}
    EOT
  }
  depends_on = ["packet_device.monitor"]
}

output "monitor_ip" {
  value = "${packet_device.monitor.access_public_ipv4}"
}
output "osds_ips" {
  value = "${packet_device.osd.*.access_public_ipv4}"
}
