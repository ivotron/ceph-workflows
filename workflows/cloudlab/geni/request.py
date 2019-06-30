import os

# from geni.aggregate import cloudlab as agg
# from geni.aggregate import apt as agg
from geni.aggregate import protogeni as agg
from geni.rspec import pg
from geni import util


experiment_name = 'ceph-benchmarks'
img = "urn:publicid:IDN+clemson.cloudlab.us+image+schedock-PG0:ubuntu18-docker"
num_osds = 3

# comment/uncomment aggregate imports above accordingly and then replace the
# site variable with agg.Clemson, agg.Utah, agg.Wisconsin (cloudlab) or agg.Apt
# (apt). Check hardware availability and types at www.cloudlab.us/resinfo.php
site = agg.UTAH_PG
hw_type = 'd430'


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
            pg.IPv4Address("192.168.1.{}".format(i), "255.255.255.0"))
        lan.addInterface(iface)


request = pg.Request()
nodes = []

# add mon node to request
nodes.append(add_baremetal_node(request, 'mon', img, hw_type))

# add osd nodes to request
for n in range(num_osds):
    nodes.append(add_baremetal_node(request, 'osd{}'.format(n), img, hw_type))

# add lan to request
add_lan(request, nodes)

# load context
ctx = util.loadContext(key_passphrase=os.environ['GENI_KEY_PASSPHRASE'])

# create slice
util.createSlice(ctx, experiment_name, renew_if_exists=True)

# create sliver on selected site
manifest = util.createSliver(ctx, site, experiment_name, request)

# output files: ansible inventory and GENI manifest
# {
outdir = os.path.dirname(os.path.realpath(__file__))
groups = {
  'mons': ['mon'],
  'osds': ['osd{}'.format(n) for n in range(num_osds)]
}
util.toAnsibleInventory(manifest, groups=groups, hostsfile=outdir+'/hosts')
manifest.writeXML(outdir+'/manifest.xml')
# }
