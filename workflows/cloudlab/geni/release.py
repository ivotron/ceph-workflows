import os

from geni.aggregate import cloudlab as agg
from geni import util


ctx = util.loadContext(key_passphrase=os.environ['GENI_KEY_PASSPHRASE'])
experiment = 'ceph-benchmarks'

print("Available slices: {}".format(ctx.cf.listSlices(ctx).keys()))

if util.sliceExists(ctx, experiment):
    print('Slice exists.')
    print('Removing sliver (errors are ignored)')
    util.deleteSliverExists(agg.Clemson, ctx, experiment)
else:
    print("Slice does not exist.")
