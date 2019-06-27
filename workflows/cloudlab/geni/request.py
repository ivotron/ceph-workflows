import itertools
import os

from geni.aggregate import cloudlab
from geni.rspec import pg
from geni import util


def baremetal_node(name, img, hardware_type):
    node = pg.RawPC(name)
    node.disk_image = img
    node.hardware_type = hardware_type
    return node


def link_all_to_all(request, nodes):
    # create interface for each node
    ifaces = {}
    for i, n in enumerate(nodes):
        iface = n.addInterface("if1")
        iface.addAddress(
            pg.IPv4Address("192.168.1.{}".format(i), "255.255.255.0"))
        ifaces.update({n: iface})

    # create links between each pair of nodes
    for (n1, n2) in list(itertools.combinations(nodes, 2)):
        link = request.LAN("lan")
        link.addInterface(ifaces[n1])
        link.addInterface(ifaces[n2])


experiment_name = 'popper-examples'
img = "urn:publicid:IDN+clemson.cloudlab.us+image+schedock-PG0:ubuntu18-docker"
num_osds = 3

request = pg.Request()
nodes = []

# add monitor node to request
nodes.append(request.addResource(baremetal_node('mon', img, 'c6320')))

# add OSD nodes to request
for n in range(num_osds+1):
    nodes.append(
        request.addResource(baremetal_node('osd-{}'.format(n), img, 'c6320')))

# add links to request
link_all_to_all(request, nodes)

# load context
ctx = util.loadContext(key_passphrase=os.environ['GENI_KEY_PASSPHRASE'])

# create slice
util.createSlice(ctx, experiment_name, renew_if_exists=True)

# create sliver on clemson
manifest = util.createSliver(ctx, cloudlab.Clemson, experiment_name, request)

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
