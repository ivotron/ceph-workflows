import os
import sys

from collections import OrderedDict

from geni.aggregate import apt
from geni.aggregate import protogeni
from geni.aggregate import cloudlab
from geni.rspec import pg
from geni import util

# name of experiment to use to identify this allocation
experiment_name = 'ceph-benchmarks'

# expiration of allocation in minutes
expiration = 180

# OS image to use
img = "urn:publicid:IDN+clemson.cloudlab.us+image+schedock-PG0:ubuntu18-docker"

# replace the site variable with cloudlab.Clemson, cloudlab.Utah,
# cloudlab.Wisconsin, apt.Apt or protogeni.UTAH_PG. Check hardware availability
# and hardware types at https://www.cloudlab.us/resinfo.php
site = cloudlab.Clemson
hw_type = 'c6320'

# whether to create a lan
with_lan = True

# grouping of nodes based on their ceph roles (note: insertion order in groups
# dictionary matters, as that's the order in which nodes are added to request)
num_osds = 3
groups = OrderedDict()
groups['mons'] = ['mon']
groups['mgrs'] = ['mon']
groups['osds'] = ['osd{}'.format(n) for n in range(1, num_osds+1)]

##############################################################################
#   CODE BELOW CAN BE REUSED IN OTHER EXPERIMENTS
##############################################################################

# get cmd
if len(sys.argv) != 2:
    raise Exception(
        "Expecting only 1 argument: apply, destroy, renew or inventory")
cmd = sys.argv[1]

out_dir = os.getcwd()


def create_baremetal_node(name, img, hardware_type):
    node = pg.RawPC(name)
    node.disk_image = img
    node.hardware_type = hardware_type
    return node


def create_lan(nodes):
    lan = pg.LAN("lan")

    # create an interface for each node and add it to the lan
    for i, n in enumerate(nodes):
        iface = n.addInterface("if1")
        iface.component_id = "eth1"
        iface.addAddress(
            pg.IPv4Address("192.168.1.{}".format(i+1), "255.255.255.0"))
        lan.addInterface(iface)

    return lan


def create_request(img, hw_type, groups, with_lan):
    request = pg.Request()
    nodes = []
    processed = []

    for _, group in groups.items():
        for node_name in group:
            if node_name in processed:
                # nodes can appear on multiple groups, so we check and skip
                # creating another request for the same node
                continue
            node = create_baremetal_node(node_name, img, hw_type)
            nodes.append(node)
            processed.append(node_name)
            request.addResource(node)

    # add lan to request
    if with_lan:
        lan = create_lan(nodes)
        request.addResource(lan)

    return request


if cmd == 'inventory':
    print('Creating Ansible inventory from GENI manifest.')
    geni_out_dir = out_dir + '/geni'
    ansible_out_dir = out_dir + '/ansible'
    if not os.path.isdir(geni_out_dir):
        os.makedirs(geni_out_dir)
    if not os.path.isdir(ansible_out_dir):
        os.makedirs(ansible_out_dir)
    manifest_path = geni_out_dir+'/manifest.xml'
    util.xmlManifestToAnsibleInventory(
        manifest_path,
        groups=groups,
        hostsfile=ansible_out_dir+'/hosts',
        format='yaml'
    )
    sys.exit(0)

# load context
ctx = util.loadContext(path='/geni-context.json',
                       key_passphrase=os.environ['GENI_KEY_PASSPHRASE'])

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

request = create_request(img, hw_type, groups, with_lan)

# create sliver on selected site
manifest = util.createSliver(ctx, site, experiment_name, request)

# write manifest
manifest.writeXML(out_dir+'/geni/manifest.xml')
