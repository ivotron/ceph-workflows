import os
import sys

from collections import OrderedDict

# from geni.aggregate import apt as agg
# from geni.aggregate import protogeni as agg
from geni.aggregate import cloudlab as agg
from geni.rspec import pg
from geni import util

# name of experiment to use to identify this allocation
experiment_name = 'ceph-benchmarks'

# expiration of allocation in minutes
expiration = 180

# OS image to use
img = "urn:publicid:IDN+clemson.cloudlab.us+image+schedock-PG0:ubuntu18-docker"

# comment/uncomment aggregate imports above accordingly and then replace the
# site variable with agg.Clemson, agg.Utah, agg.Wisconsin (cloudlab), agg.Apt
# (apt) or agg.UTAH_PG (emulab). Check hardware availability and hardware types
# at https://www.cloudlab.us/resinfo.php
site = agg.Clemson
hw_type = 'c6320'

# grouping of nodes based on their ceph roles (note: insertion order in groups
# dictionary matters, as that's the order in which nodes are added to request)
num_osds = 3
groups = OrderedDict()
groups['mons'] = ['mon']
groups['osds'] = ['osd{}'.format(n) for n in range(1, num_osds+1)]

##############################################################################
#   CODE BELOW CAN BE REUSED IN OTHER EXPERIMENTS
##############################################################################

# get cmd
if len(sys.argv) != 2:
    raise Exception(
        "Expecting only 1 argument: apply, destroy, renew or inventory")
cmd = sys.argv[1]

# output directory where to write files
outdir = os.path.dirname(os.path.realpath(__file__))


def add_baremetal_node(request, name, img, hardware_type):
    node = pg.RawPC(name)
    node.disk_image = img
    node.hardware_type = hardware_type
    request.addResource(node)
    return node


def add_lan(request, nodes):
    lan = request.LAN("lan")

    # create an interface for each node and add it to the lan
    for i, n in enumerate(nodes):
        iface = n.addInterface("if1")
        iface.component_id = "eth1"
        iface.addAddress(
            pg.IPv4Address("192.168.1.{}".format(i+1), "255.255.255.0"))
        lan.addInterface(iface)


def create_request(img, hw_type, groups):
    request = pg.Request()
    nodes = []

    for _, group in groups.items():
        for node_name in group:
            nodes.append(add_baremetal_node(request, node_name, img, hw_type))

    # add lan to request
    add_lan(request, nodes)

    return request


if cmd == 'inventory':
    print('Creating Ansible inventory from GENI manifest.')
    manifest_path = outdir+'/manifest.xml'
    util.xmlManifestToAnsibleInventory(
        manifest_path, groups=groups, hostsfile=outdir+'/hosts', format='yaml'
    )
    sys.exit(0)

# load context
ctx = util.loadContext(key_passphrase=os.environ['GENI_KEY_PASSPHRASE'])

if cmd == 'destroy':
    util.deleteSliverExists(site, ctx, experiment_name)
    sys.exit(0)

# create slice
util.createSlice(ctx, experiment_name, expiration=expiration,
                 renew_if_exists=True)

if cmd == 'renew':
    sys.exit(0)

if cmd != 'apply':
    print("Unknown command '{}'".format(cmd))
    sys.exit(1)

request = create_request(img, hw_type, groups)

# create sliver on selected site
manifest = util.createSliver(ctx, site, experiment_name, request)

# write manifest
manifest.writeXML(outdir+'/manifest.xml')
