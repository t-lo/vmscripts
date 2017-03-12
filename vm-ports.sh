#!/bin/bash -ue
#
# 'vmscripts' low-level VM management scripts - active VM port map listing
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

ports_usage() {
    echo " Usage:"
    echo "    vm ports <name>  -  display host port => VM port mappings."
}
# ----

vm_ports() {
    local line=""

    for line in $(set | grep -E '^vm_port_'); do
        local map=$(echo "$line" | sed -n 's/vm_port_\([0-9=]\+\)/\1/p')
        [ -z "$map" ] && continue
        local vm_port=${map/=*/}
        local host_port=${map/*=/}
        echo "$host_port => $vm_port"
    done
}
# ----

if [ `basename "$0"` = "vm-ports.sh" ] ; then
    [ "${vm_tools_initialized-NO}" != "YES" ] && {
        exec $(which vm) "ports" $@
        exit 1; }
    vm_ports $@
else
    true
fi
