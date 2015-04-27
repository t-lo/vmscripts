#!/bin/bash -ue
#
# 'vmscripts' low-level VM management scripts - active VMs listing
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

usage() {
    echo
    echo " vm attach: Illegal argument encountered."
    echo " $@"
    echo
    echo " Usage:"
    echo "    vm attach <vm-name>"
    echo
    exit 1
}
# ----

vm_attach() {
    local vm="$1"
    [ -z "$vm" ] && usage "vm-name argument is missing."
    vm ls -a | grep "$vm" || usage "VM $vm is not running."

    screen -rd "$vm"
}
# ----

if [ `basename "$0"` = "vm-attach.sh" ] ; then
    exec "$(which vm)" "attach" $@
    exit 1
else
    true
fi
