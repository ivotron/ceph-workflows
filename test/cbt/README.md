# Run CBT benchmarks

An [example workflow](./main.workflow) that runs benchmarks on a Ceph 
cluster using [`cbt`][cbt]. The workflow expects an Ansible inventory 
(in YAML format) corresponding to a Ceph deployment. For examples of 
workflows that deploy Ceph and generate this inventory, see the 
[`workflows/deploy`](../../deploy) folder. The actions in these 
workflow accomplish the following:

  * **`install jinja2-cli`**. Installs the [Jinja2 CLI][jinja2] 
    utility that is used to generate a CBT configuration from an 
    Ansible inventory file.

  * **`generate cbt config`**. Generate a CBT configuration by passing 
    the [Jinja2 template](./config.yml.j2) and the inventory available 
    in the `ansible/` folder to the `jinja2` command.

  * **`run benchmarks`**. Passes the config file generated previously, 
    along with the `ceph.conf` for the cluster to CBT and executes the 
    benchmark. The output is stored in the `./resuilts` folder.

To execute this workflow, we first clone this repository:

```bash
git clone https://github.com/popperized/ceph

cd ceph/workflows/bench/cbt
```

Then, we either copy-paste the actions contained in any of the 
workflows in [`workflows/deploy`](../../deploy); or copy an inventory 
file and `ceph.conf` file to the `ansible/` folder. Next, we define 
the secrets expected by the workflow (those declared in the `secrets` 
attribute) as bash environment and then execute the following:

```bash
popper run
```

For more information on Github Action workflows and Popper visit 
<https://github.com/systemslab/popper>.

[jinja2]: https://github.com/mattrobenolt/jinja2-cli
[ceph-ansible]: https://github.com/ceph/ceph-ansible
[geni]: https://github.com/popperized/geni
[aa]: https://github.com/popperized/ansible
[ca-docs]: http://docs.ceph.com/ceph-ansible/master/
