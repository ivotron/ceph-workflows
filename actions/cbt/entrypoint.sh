#!/bin/bash
set -e

if [ -z "$PDSH_SSH_KEY_DATA" ]; then
  echo "Expecting PDSH_SSH_KEY_DATA"
  exit 1
fi

echo "$PDSH_SSH_KEY_DATA" | base64 --decode > /tmp/ssh.key
chmod 400 /tmp/ssh.key

PDSH_SSH_ARGS_APPEND="$PDSH_SSH_ARGS_APPEND -i /tmp/ssh.key"

python /cbt/cbt.py "$@"
