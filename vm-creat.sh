#!/bin/bash -ue
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
def_forward_ports="22,25,80"

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
    echo -n "  vm creat <name> [-m] [<disk-size-or-path-to-image>] [<path-to-iso-image>]"
    echo " [<mem-size>] [<nr-of-cpus>] [<internal-network>] [<list-of-forwarded-ports>]"
    echo
    echo " All arguments must be provided in order. The [-m] flag may be omitted, though."
    echo " Using '-' for a parameter will use its default."
    echo
    echo "   <name>                        unique identifier for this VM"
    echo "  [-m]                           Move source disk image and ISO instead of copying."
    echo "  [<disk-size-or-path-to-image>] Either the size of the harddisk image"
    echo "                                 (followed by K, M, G or T)"
    echo "                                 or path to an existing image"
    echo "                                 (which will be copied). Default: $def_disk"
    echo "  [<path-to-iso-image>]          Path to an ISO image to use with the VM"
    echo "  [<mem-size>]                   Amount of memory (followed by M or G). Default: $def_mem"
    echo "  [<nr-of-cpus>]                 Virtual CPUs count. Default: $def_cpu"
    echo "  [<internal-network>]           VM-internal network. Default: $def_net"
    echo "  [<list-of-forwarded-ports>]    List of ports forwarded to host ports,"
    echo "                                 separated by comma (e.g.  '22,80,554')"
}
# ----

creat_complete() {
    local cword="$1"; shift
    local words=( $@ )
    [ "${words[3]-}" = "-m" ] && cword="$((cword-1))"
    local cur="${words[$cword]-}"

    case $cword in
        3) echo -n "---DEFAULT---" ;;
        4) echo -n "---DEFAULT---" ;;
    esac
}
# ----

image_and_iso() {
    local op="$1"
    local disk="$2"
    local iso="$3"

    [ -e "$vm_path" ] && \
        die "The path '$vm_path' already exists. Remove it or choose a different name for the VM."

    mkdir "$vm_path"
    local img="$vm_path/${name}.img"
    if [ -e "$disk" ] ; then
        $op -v "$disk" "$img"
    else
        qemu-img create -f raw "$img" "$disk"
    fi

    img="$vm_path/${name}.iso"
    if [ -e "$iso" ] ; then
        $op -v "$iso" "$img"
    fi
}
# ----

write_config() {
    echo "$1=\"$2\"" >> "$vm_config"
}
# ----

val_or_def() {
    local val="$1"
    local def="$2"

    if [ -z "$val" -o "$val" = "-" ] ; then
        echo "$def"
    else
        echo "$val"
    fi
}
# ----

vm_creat() {
    local name="$1"
    local disk_size_or_image=$(val_or_def "${2-}" "${def_disk}")
    local cp_mv="cp"
    [ "$disk_size_or_image" = "-m" ] && {
        cp_mv="mv"
        shift
        disk_size_or_image=$(val_or_def "${2-}" "${def_disk}") ; }
    local iso_image=$(val_or_def "${3-}" "")
    local mem=$(val_or_def "${4-}" "${def_mem}")
    local cpu=$(val_or_def "${5-}" "${def_cpu}")
    local net=$(val_or_def "${6-}" "${def_net}")
    local ports=$(val_or_def "${7-}" "${def_forward_ports}")
    image_and_iso "$cp_mv" "$disk_size_or_image" "$iso_image"

    rm -f "$vm_config"
    write_config "net" "$net"
    write_config "cpu" "$cpu"
    write_config "mem" "$mem"
    write_config "forward_ports" "${ports//,/ }"

    echo
    echo " VM $vm_name generated."
    echo
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
