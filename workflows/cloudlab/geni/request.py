import os

# from geni.aggregate import cloudlab
from geni.aggregate import protogeni
from geni.rspec import pg
from geni import util


def baremetal_node(request, name, img, hardware_type):
    node = pg.RawPC(name)
    node.disk_image = img
    node.hardware_type = hardware_type
    request.addResource(node)
    return node


def link_all_to_all(request, nodes):
    link = request.LAN("lan")

    # create an interface for each node and add it to the link
    for i, n in enumerate(nodes):
        iface = n.addInterface("if1")
        iface.component_id = "eth1"
        iface.addAddress(
            pg.IPv4Address("192.168.1.{}".format(i), "255.255.255.0"))
        link.addInterface(iface)


experiment_name = 'ceph-benchmarks'
img = "urn:publicid:IDN+clemson.cloudlab.us+image+schedock-PG0:ubuntu18-docker"
num_osds = 2

request = pg.Request()
nodes = []

# add mon node to request
# nodes.append(baremetal_node(request, 'mon', img, 'c6320'))
nodes.append(baremetal_node(request, 'mon', img, 'd430'))

# add osd nodes to request
for n in range(num_osds+1):
    # nodes.append(baremetal_node(request, 'osd{}'.format(n), img, 'c6320'))
    nodes.append(baremetal_node(request, 'osd{}'.format(n), img, 'd430'))

# add links to request
link_all_to_all(request, nodes)

# load context
ctx = util.loadContext(key_passphrase=os.environ['GENI_KEY_PASSPHRASE'])

# create slice
util.createSlice(ctx, experiment_name, renew_if_exists=True)

# create sliver on clemson
manifest = util.createSliver(ctx, protogeni.UTAH_PG, experiment_name, request)

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

