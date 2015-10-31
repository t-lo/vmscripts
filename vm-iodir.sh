#!/bin/bash -ue
#
# 'vmscripts' low-level VM management scripts - io directory printer
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

vmscripts_prereq="exist"

iodir_usage() {
    echo " Usage:"
    echo "    vm iodir <name>  -  print VM's IO directory."
}
# ----

vm_iodir() {
    local line=""

    echo "$vm_iodir => /_io"
}
# ----

if [ `basename "$0"` = "vm-iodir.sh" ] ; then
    [ "${vm_tools_initialized-NO}" != "YES" ] && {
        exec $(which vm) "iodir" $@
        exit 1; }
    vm_iodir $@
else
    true
fi
