#!/bin/bash
#
# 'vmscripts' low-level VM management scripts - VM creator
#
# Copyright © 2015 Thilo Fromm. Released under the terms of the GNU GLP v3.
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

# the defaults
def_disk="4G"
def_mem="512M"
def_cpu="1"
def_net="172.16.10.0/24"
def_forward_ports="22 25 80"

# Create a VM (i.e. add it to vmtools)
# Properties from cmdl. arguments:
#  1. name
#  2. disk size or existing image
#  3. ISO image
#  4. MEM size
#  5. Nr. of CPUs
#  6. internal network + mask
#  7. forwarded ports (default: 22, 25, 80)
# -provide defaults, generate .cfg
# -create / move existing image in .vmscripts/<name>/<name>.raw, .iso

#
# VM preparation
#  This could be done with a linux VM after creation (may be automated):
#
# - Serial output:
#   in /etc/default/grub:
#    GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,1152008n1"
#    GRUB_TERMINAL=serial
#    GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
#
#   then:
#    update-grub
#
# - Configure dhcp networking
#
# - SSH id:
#    source ./start.sh
#    mkdir -p .ssh
#    ssh-keygen -f .ssh/id_rsa.test_vm
#    ssh-copy-id -i .ssh/id_rsa.test_vm.pub -p $ssh_port root@localhost
#    ssh-copy-id -i .ssh/id_rsa.test_vm.pub -p $ssh_port user@localhost
#
# - mount the local export dir:
#   mount -t 9p -o trans=virtio export /<whereever> -oversion=9p2000.L,posixacl,cache=none
#   (check mtab entry; move to fstab)
#
# ----
#  Ideas
#  - deb / rpm package generator w/ centralized scripts
#  - system wide and per-user configurations and images
#  - automated VM preparation (needs root pw, VM must boot via DHCP)
# ----

vmscripts_prereq="name"

creat_usage () {
    echo " Usage:"
    echo -n "  vm creat <name> [<disk-size-or-path-to-image>] [<mem-size>]"
    echo " [<nr-of-cpus>] [<internal-network>] [<list-of-forwarded-ports>]"
    echo
    echo "   <name>                        unique identifier for this VM"
    echo "  [<disk-size-or-path-to-image>] Either the size of the harddisk image"
    echo "                                 (followed by K, M, G or T)"
    echo "                                 or path to an existing image"
    echo "                                 (which will be copied). Default: $def_disk"
    echo "  [<mem-size>]                   Amount of memory (followed by M or G). Default: $def_mem"
    echo "  [<nr-of-cpus>]                 Virtual CPUs count. Default: $def_cpu"
    echo "  [<internal-network>]           VM-internal network. Default: $def_net"
    echo "  [<list-of-forwarded-ports>]    List of ports forwarded to host ports."
}
# ----
vm_creat() {

    [ "${1-}" = "" ] && usage "<name> argument is not optional."
    [ "$1" = "-h" ] && usage

    local name="$1"

}
# ----

if [ `basename "$0"` = "vm-creat.sh" ] ; then
    [ "${vm_tools_initialized-NO}" != "YES" ] && {
        exec $(which vm) "creat" $@
        exit 1; }
    vm_creat $@
else
    true
fi
