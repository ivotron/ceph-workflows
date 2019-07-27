# Build Ceph Using CMake

The [workflow in this folder](./main.workflow) compiles Ceph using the 
[CMake action][cmake]. It takes a relative short amount of time to 
execute since it only compiles the Ceph monitor and OSD daemons. It 
consists of a single action and takes CMake variables via the `env` 
attribute of action blocks.

## Local Development

This workflow can be used to develop and test Ceph locally:

```bash
git clone --recursive https://github.com/popperized/ceph-actions

cd ceph-actions/workflows/dev/cmake
```

Modify the CMake options specified in `env` attribute of the workflow 
file to fit your build goals and then execute:

```bash
popper run
```

> _**NOTE**: to avoid having to install dependencies every time that 
> the workflow runs, add the `--reuse` flag to `popper run`._

After the above finishes, the `ceph/build` folder will contain all the 
binaries that were compiled.

### Run a Single-node Cluster

Once the `popper run` command finishes, we can run Ceph by 
instantiating a container from the container image associated to the 
`build` action. For example:

```bash
cd ceph-actions/workflows/dev

docker run --rm -ti --entrypoint=/bin/bash \
  --volume $PWD:$PWD \
  --workdir=$PWD
  popperized/cmake:master
```

> **NOTE**: `popperized/cmake:master` is the image resulting from 
> running the workflow.

The above puts us inside a container. There, we can type:

```bash
cd ceph/build
MON=1 OSD=1 MGR=0 MDS=0 ../src/vstart.sh -d -X -n
bin/ceph -s
```

For more on how to use the `vstart.sh` script see [here][quickguide].

[liststxt]: https://github.com/ceph/ceph/blob/master/CMakeLists.txt
[quickguide]: http://docs.ceph.com/docs/mimic/dev/quick_guide/
[cmake]: https://github.com/popperized/cmake
