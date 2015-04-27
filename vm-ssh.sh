#!/bin/bash

vm_ssh() {
    shift
    [ -z "${vm_port_22-}" ] && \
        die " connecting to $vm_name via SSH:
    No ssh port forwarding has been configured for VM $vm_name.
    Please add '22' to the list of forwarded ports in 
        $vm_config"

    ssh     -i "$vm_path/.ssh/id_rsa"       \
            -o UserKnownHostsFile=/dev/null \
            -o StrictHostKeyChecking=no     \
            -o ConnectTimeout=1             \
            -o TCPKeepAlive=yes             \
            -o LogLevel=quiet               \
            -q                              \
            -p $vm_port_22 root@localhost "$@"
}
# ----

if [ `basename "$0"` = "vm-ssh.sh" ] ; then
    [ "${vm_tools_initialized-NO}" != "YES" ] && {
        exec $(which vm) "ssh" $@
        exit 1; }
    vm_ssh $@
else
    true
fi
