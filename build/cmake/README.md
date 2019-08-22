# Build Ceph Using CMake

The [workflow in this folder](./main.workflow) compiles Ceph using a 
[ceph builder docker image][ceph-builder]. It consists of a single 
action:

```hcl
workflow "build ceph" {
  resolves = "build"
}

action "build" {
  uses = "docker://popperized/ceph-builder:nautilus-bionic"
  args = "vstart"
  env = {
    CMAKE_FLAGS = "-DCMAKE_BUILD_TYPE=MinSizeRel -DWITH_RBD=OFF -DWITH_CEPHFS=OFF -DWITH_RADOSGW=OFF -DWITH_LEVELDB=OFF -DWITH_MANPAGE=OFF -DWITH_RDMA=OFF -DWITH_OPENLDAP=OFF -DWITH_FUSE=OFF -DWITH_LIBCEPHFS=OFF -DWITH_KRBD=OFF -DWITH_LTTNG=OFF -DWITH_BABELTRACE=OFF -DWITH_SYSTEMD=OFF -DWITH_SPDK=OFF -DWITH_CCACHE=ON -DBOOST_J=16"
    BUILD_THREADS = "16"
  }
}
```

The docker image can read CMake variables via the `env` attribute of 
action blocks. For more information on which variables can be passed 
to this image, see the [corresponding Github 
repository][ceph-builder].

## Local Development

This workflow can be used to develop and test Ceph locally:

```bash
git clone --recursive https://github.com/popperized/ceph-workflows

cd ceph-workflows/build/cmake
```

> **NOTE**: the `--recursive` flag is required in order to clone the 
> Ceph repository that is added as submodule to this repository (which 
> resides in the `ceph-workflow/build/ceph` folder).

After cloning this repository, modify the CMake options specified via 
the `env` attribute in the workflow file to fit your build goals and 
then execute:

```bash
popper run
```

After the above finishes, the `ceph/build` folder will contain all the binaries 
that were compiled.

### Run a Single-node Cluster

Once the `popper run` command finishes, we can run Ceph by 
instantiating a container from the same builder image that was in the 
`build` action. For example:

```bash
cd ceph-workflows/build/

docker run --rm -ti \
  --volume $PWD:$PWD \
  --workdir=$PWD \
  --entrypoint=/bin/bash \
  popperized/ceph-builder:nautilus-bionic
```

The above puts us inside a container. There, we can type:

```bash
cd ceph/build
MON=1 OSD=1 MGR=0 MDS=0 ../src/vstart.sh -d -X -n
bin/ceph -s
```

For more on how to use the `vstart.sh` script see [here][quickguide].

[liststxt]: https://github.com/ceph/ceph/blob/master/CMakeLists.txt
[quickguide]: http://docs.ceph.com/docs/mimic/dev/quick_guide/
[ceph-builder]: https://github.com/systemslab/ceph-builder
