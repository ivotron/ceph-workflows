# Builder action

This action compiles Ceph, using build dependencies specific to a 
branch. It optionally produces a docker image compatible with 
`ceph-ansible`.

## Usage

An example of how to use it in a Github Actions workflow:

```hcl
workflow "build ceph" {
  on = "push"
  resolves = "build src"
}

action "build src" {
  uses = "docker://popperized/ceph-builder:nautilus"
  arg = "vstart"
  env = {
    CEPH_SRC_DIR = "./path/to/ceph",
    CEPH_CMAKE_FLAGS = "-DWITH_MGR=OFF"
  }
}
```

In the above example, the build dependencies used to compile the code 
correspond to the `nautilus` branch (hence the `:nautilus` tag). The 
argument to the action is passed to `make` "as is" (`vstart` in the 
example above). The newly created binaries are available in the 
`ceph/build/` folder (`./path/to/ceph/build` in the example above).

## Environment

  * `CEPH_SRC_DIR`. Path to the folder in the workspace containing the 
    source code for Ceph.

  * `CEPH_CMAKE_FLAGS`. Flags that are passed to `cmake` when 
    configuring the project.

  * `CEPH_CMAKE_RECONFIGURE`. If its value is `true`, forces a 
    reconfiguration of the project by calling `cmake` again. Default: 
    `false`.

  * `CEPH_CMAKE_CLEAN`. If its value is `true`, removes the `build/` 
    directory and invokes `cmake` on a freshly created (and empty) 
    `build/` folder. Default: `false`.

  * `CEPH_BUILD_THREADS`. Number of threads given to `make` (via the 
    `-j` flag). Default: all cores in the machine.

  * `CEPH_OUTPUT_DOCKER_IMAGE`. If given, a docker image is created 
    and tagged with this name. The image will contain the binaries 
    that have just been compiled, installed in `/usr` (inside the 
    container image). For more on how this image can be used in 
    workflows, please check the [`ansible` action](../ansible) for 
    Ceph. Default: empty.

## Minimal Build

This is an example workflow that takes a relative short amount of time 
to execute. It only compiles the Ceph monitor and OSD daemons.

```hcl
workflow "build and deploy ceph" {
  resolves = "build src"
}
action "build src" {
  uses = "docker://popperized/ceph-builder:nautilus"
  args = "vstart"
  env = {
    CEPH_SRC_DIR = "./ceph"
    CEPH_CMAKE_FLAGS = "-DCMAKE_BUILD_TYPE=MinSizeRel -DWITH_RBD=OFF -DWITH_CEPHFS=OFF -DWITH_RADOSGW=OFF -DWITH_MGR=OFF -DWITH_LEVELDB=OFF -DWITH_MANPAGE=OFF -DWITH_RDMA=OFF -DWITH_OPENLDAP=OFF -DWITH_FUSE=OFF -DWITH_LIBCEPHFS=OFF -DWITH_KRBD=OFF -DWITH_LTTNG=OFF -DWITH_BABELTRACE=OFF -DWITH_TESTS=OFF -DWITH_MGR_DASHBOARD_FRONTEND=OFF -DWITH_SYSTEMD=OFF -DWITH_SPDK=OFF"
  }
}
```

Consult the 
[`CMakeLists.txt`](https://github.com/ceph/ceph/blob/master/CMakeLists.txt) 
file on the Ceph repo to learn more about what these switches do. Keep 
in mind that distinct branches have distinct CMake configuration and 
flags available.

## Local Development

This action can be used to develop and test Ceph locally. To execute a 
workflow locally, we can use 
[Popper](https://github.com/systemslab/popper). For example:

```bash
mkdir myproject
cd myproject

# initialize the repository
git init
echo '# My Ceph Project' > README.md
git commit -m 'first commit'

# then we add ceph as a submodule
git submodule --branch nautilus --depth=1 https://github.com/ceph/ceph
git add .
git commit -m 'adds ceph as submodule'

# create a main.workflow file such as the minimal defined above

# we then run the workflow
popper run
```

After the above finishes, the `myproject/ceph/build` folder will 
contain all the binaries that were compiled.

### Run a Single-node Cluster

Once the `popper run` command finishes, we can create a container 
using this same image to test. For example, assuming we built the 
minimal configuration shown above:

```bash
cd myproject/

docker run --rm -ti --entrypoint=/bin/bash \
  --volume $PWD:$PWD \
  --workdir=$PWD
  popperized/ceph-builder:nautilus
```

The above puts us inside a container. There, we can type:

```bash
cd ceph/build
MON=1 OSD=1 MGR=0 MDS=0 ../src/vstart.sh -d -X -n
bin/ceph -s
```

For more on how to use the `vstart.sh` script, see 
[here](http://docs.ceph.com/docs/mimic/dev/quick_guide/).
