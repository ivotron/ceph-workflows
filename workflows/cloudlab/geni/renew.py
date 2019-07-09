import os

from geni import util

experiment_name = 'ceph-benchmarks'

ctx = util.loadContext(key_passphrase=os.environ['GENI_KEY_PASSPHRASE'])

util.createSlice(ctx, experiment_name, renew_if_exists=True)
