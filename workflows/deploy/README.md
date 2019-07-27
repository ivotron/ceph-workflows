# Deployment Workflows

These workflows deploy Ceph on multiple infrastructures using 
[`ceph-ansible`][ceph-ansible]. All of them generate an Ansible 
inventory and a `ceph.conf` file that can be used to obtain 
information and connect to a cluster to run subsequent tests. Take a 
look at the [`workflows/bench/`](../bench) folder for examples.

[ceph-ansible]: https://github.com/ceph/ceph-ansible
