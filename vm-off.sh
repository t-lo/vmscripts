#!/bin/bash -u -e
#
# 'vmscripts' low-level VM management scripts VM poweroff script
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


vm_off() {
    (sleep 1; echo "quit") | nc 127.0.0.1 "$vm_port_hmp" >/dev/null 2>&1
    rm -f "$vm_pidfile"
}
# ----

if [ `basename "$0"` = "vm-off.sh" ] ; then
    [ "${vm_tools_initialized-NO}" != "YES" ] && {
        exec $(which vm) "off" $@
        exit 1; }
    vm_off $@
else
    true
fi
