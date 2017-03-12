#!/bin/bash
#
# 'vmscripts' low-level VM management scripts VM SSH script
#
# Copyright © 2015, 2016, 2017 Thilo Fromm. Released under the terms of the GNU
#    GLP v3.
#
#    vmscripts is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    vmscripts is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with vmscripts. If not, see <http://www.gnu.org/licenses/>.#
#

vmscripts_prereq="active"

ssh_usage() {
    echo " Usage:"
    echo "    vm ssh <name> [<cmd>] - Connect to <name> via ssh, optinally executing <cmd>."
}
# ----

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
