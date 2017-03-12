#!/bin/bash -ue
#
# 'vmscripts' low-level VM management scripts - remove a VM
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

purge_usage() {
    echo " Usage:"
    echo "    vm purge <name> - Completely remove a VM from the system."
}
# ----

vm_purge() {
    vm ls -a | grep "$vm_name" && {
        echo "Stopping VM $vm_name"
        vm off "$vm_name" ; }
    echo "Purging VM $vm_name"
    rm -rf "$vm_path"
}
# ----

if [ `basename "$0"` = "vm-purge.sh" ] ; then
    [ "${vm_tools_initialized-NO}" != "YES" ] && {
        exec $(which vm) "purge" $@
        exit 1; }
    vm_purge $@
else
    true
fi
