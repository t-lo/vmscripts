#!/bin/bash

cd $(dirname ${BASH_SOURCE[0]})
source start.sh

ssh     -i .ssh/id_rsa.test_vm          \
        -o UserKnownHostsFile=/dev/null \
        -o StrictHostKeyChecking=no     \
        -o ConnectTimeout=1             \
        -o TCPKeepAlive=yes             \
        -o LogLevel=quiet               \
        -q                              \
        root@172.16.10.2 "$@"
