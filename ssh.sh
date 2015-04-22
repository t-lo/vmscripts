#!/bin/bash

cd $(dirname ${BASH_SOURCE[0]})
source start.sh

[ -z "$port_22" ] && {
    echo
    echo "ERROR connecting to $name via SSH:"
    echo " No ssh port forwarding has been configured for VM $name."
    echo " Please add '22' to the list of forwarded ports."
    echo
    exit 1; }

ssh     -i .ssh/id_rsa.test_vm          \
        -o UserKnownHostsFile=/dev/null \
        -o StrictHostKeyChecking=no     \
        -o ConnectTimeout=1             \
        -o TCPKeepAlive=yes             \
        -o LogLevel=quiet               \
        -q                              \
        -p $port_22 root@localhost "$@"
