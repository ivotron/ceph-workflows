# Deploy Ceph on CloudLab

This workflow deploys Ceph on a [Cloudlab][cloudlab] allocation using 
[`ceph-ansible`][ceph-ansible]. The workflow consists of the following 
actions:

  * **`allocate resources`**. Request for resources to Cloudlab and 
    wait for them to be instantiated. The configuration is specified 
    in the [`geni/config.py`](./geni/config.py)

  * **`generate ansible inventory`**. Generates an Ansible inventory 
    out of the GENI manifest produced by the previous `allocate 
    resources` action. This is used by the subsequent `deploy` step.

  * **`download ceph-ansible`**. Downloads a specific version of 
    Ansible. The version is specified in the `runs` attribute of the 
    step definition. For more information on which version of 
    `ceph-ansible` corresponds to which version of Ceph, check the 
    [official `ceph-ansible` documentation][ca-docs].

  * **`deploy`**. Deploys Ceph by passing 
    [`ansible/playbook.yml`](./ansible/playbook.yml) and 
    [`ansible/group_vars`](./ansible/group_vars) as arguments to the 
    ansible image. After this step executes, the resulting `ceph.conf` 
    file is placed in [`ansible/fetch/`](./ansible/fetch). 

In addition to the above, subsequent steps can be added to the 
workflow in order to run tests, benchmarks or other workloads that 
work on Ceph. Take a look at the [`test`](../../test) folder for 
examples.

This workflow also includes a (commented out) `teardown` step that 
releases the allocated resources in CloudLab and can be invoked to 
release resources.

## Usage

To execute this workflow, clone this repository or copy the contents 
of this folder into your project:

```bash
git clone https://github.com/popperized/ceph-workflows
cd ceph-workflows/deploy/cloudlab
```

Define the secrets expected by the workflow, declared in the `secrets` 
attribute of the `allocate resources` step. See [the GENI image]() for 
information about how what those steps do, and [here]() for the 
Ansible step. Once this is done, execute the workflow by doing:

```bash
popper run -f wf.yml
```

For more information on Popper, visit 
<https://github.com/systemslab/popper>.

[cloudlab]: https://cloudlab.us
[ceph-ansible]: https://github.com/ceph/ceph-ansible
[geni]: https://github.com/popperized/geni
[aa]: https://github.com/popperized/ansible
[ca-docs]: http://docs.ceph.com/ceph-ansible/master/
