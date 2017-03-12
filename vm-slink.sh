#!/bin/bash -ue
#
# 'vmscripts' low-level VM management scripts - soft-link a VM from an existing VM
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

vmscripts_prereq="exist"

slink_usage() {
    echo " Usage:"
    echo "    vm slink <source> <dest> - soft-link a VM to a new VM."
}
# ----

vm_slink() {
    local dest="${2-}"
    local path="$VM_CONFIG_PATH/$dest"

    [ "$dest" = "" ]    && usage "The <dest> argument is mandatory."
    [ -e "$path" ] && \
        die "VM path '$path' already exists. Use 'vm purge $dest' to remove it."

    mkdir -p "$path"
    cp -v "$vm_config" "$path/${dest}.cfg"

    [ -e "$vm_disk_image" ] && ln -s "$vm_disk_image" "$path/${dest}.img"
    [ -e "$vm_iso_image" ]  && ln -s "$vm_iso_image"  "$path/${dest}.iso"

    local srcpath="$VM_CONFIG_PATH/$vm_name"
    [ -e "$srcpath/.ssh" ]  && ln -s "$srcpath/.ssh"  "$path/"

    echo "$dest is now soft-linked to ${vm_name}."
}
# ----

if [ `basename "$0"` = "vm-slink.sh" ] ; then
    [ "${vm_tools_initialized-NO}" != "YES" ] && {
        exec $(which vm) "slink" $@
        exit 1; }
    vm_slink $@
else
    true
fi
