# Deploy Ceph on Cloudlab

An [example workflow](./main.workflow) that deploys Ceph on a 
[Cloudlab][cloudlab] allocation using [`ceph-ansible`][ceph-ansible]. 
The workflow consists of the following actions:

  * **`build context`**. Builds a GENI context using Cloudlab active 
    credentials. For more on how to obtain these credentials check the 
    [GENI action documentation][geni].

  * **`allocate resources`**. Request for resources to Cloudlab and 
    wait for them to be instantiated. The configuration is specified 
    in the [`geni/config.py`](./geni/config.py)

  * **`generate ansible inventory`**. Generates an Ansible inventory 
    out of the GENI manifest produced by the previous `allocate 
    resources` action. This is used by the subsequent `deploy` action.

  * **`download ceph-ansible`**. Downloads a specific version of 
    Ansible. The version is specified in the `runs` attribute of the 
    action block. For more information on which version of 
    `ceph-ansible` corresponds to which version of Ceph, check the 
    [official `ceph-ansible` documentation][ca-docs].

  * **`deploy`**. Deploys Ceph by passing 
    [`ansible/playbook.yml`](./ansible/playbook.yml) and 
    [`ansible/group_vars`](./ansible/group_vars) as arguments to the 
    [Ansible action][aa]. After this action is executed, the resulting 
    `ceph.conf` file is placed in [`ansible/fetch/`](./ansible/fetch). 

Take a look at the [`workflows/bench`](../../bench) folder for 
examples of actions that can be added after the `deploy` action. This 
workflow also includes a (commented out) `teardown` action that 
releases the allocated resources in Cloudlad and can be invoked to 
teardown the cluster.

To execute this workflow, define the secrets expected by the workflow 
(those declared in the `secrets` attribute) in your bash environment 
and then execute the following:

```bash
git clone https://github.com/popperized/ceph

cd ceph/workflows/deploy/cloudlab

popper run
```

For more information on Github Action workflows and Popper visit 
<https://github.com/systemslab/popper>.

[cloudlab]: https://cloudlab.us
[ceph-ansible]: https://github.com/ceph/ceph-ansible
[geni]: https://github.com/popperized/geni
[aa]: https://github.com/popperized/ansible
[ca-docs]: http://docs.ceph.com/ceph-ansible/master/
