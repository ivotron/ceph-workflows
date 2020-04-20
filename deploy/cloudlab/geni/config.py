import cloudlab_cmd
from collections import OrderedDict

# name of experiment to use to identify this allocation
experiment_name = 'multi-node-ceph-benchmarks'

# expiration of allocation in minutes
expiration = 180

# OS image to use
img = "urn:publicid:IDN+clemson.cloudlab.us+image+schedock-PG0:ubuntu18-docker"

# check availability and types at https://www.cloudlab.us/resinfo.php
site = 'clemson'
hw_type = 'c6320'

# whether to create a lan connecting all nodes
with_lan = True

# grouping of nodes based on their ceph roles (note: insertion order in groups
# dictionary matters, as that's the order in which nodes are added to request)
num_osds = 3
groups = OrderedDict()
groups['mons'] = ['mon']
groups['mgrs'] = ['mon']
groups['osds'] = ['osd{}'.format(n) for n in range(1, num_osds+1)]

cloudlab_cmd.run(experiment_name, expiration, site, groups, hw_type, img,
                 with_lan)
