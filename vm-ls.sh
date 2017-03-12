#!/bin/bash -ue
#
# 'vmscripts' low-level VM management scripts - active VMs listing
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

vmscripts_prereq="none"

ls_shortopts="-a -t"
ls_longopts="--active --tap"

ls_usage() {
    echo " Usage:"
    echo "    vm ls [-a|--active] [-t|--tap] - List VMs."
    echo
    echo " Optional arguments include:"
    echo
    echo "    -a|--active    List started / running VMs only."
    echo "    -t|--tap       List VMs using TAP networking only."
}
# ----

vm_ls_active() {
    local line=""
    for line in $(screen -ls | grep '\-vmscripts' | awk '{print $1}'); do
        echo "${line/-vmscripts/}" | sed 's/^[0-9]\+\.//g'
    done

}
# ----

vm_ls() {
    local opts ls_act=false ls_tap=false
    opts=$(getopt -o at -l "active,tap" -n "vm ls" -- "$@")

    for o in $opts; do
        case $o in
            -a|--active)    ls_act=true;;
            -t|--tap)       ls_tap=true;;
        esac
    done

    local active="$(vm_ls_active | sed 's/^\(.*\)$/ \1 /')"

    for name in $(ls -1 "$VM_CONFIG_PATH/") ; do
        [ ! -d "$VM_CONFIG_PATH/$name" ] && continue
        local aflag="" lflag=""
        # check for soft-linked VM; display link source
        if [ -L "$VM_CONFIG_PATH/$name/${name}.img" ] ; then
            local src=$(basename                                    \
                    $(readlink "$VM_CONFIG_PATH/$name/${name}.img"  \
                        | sed 's/\.img//'))
            lflag="(->$src)"
        fi

        # check whether it's currently active
        if   echo "$active" | grep -qw " $name "; then
            aflag="(active)"
        elif $ls_act ; then
            continue
        fi

        local net="" netmode="" cpu="" mem="" forward_ports=""
        source "$VM_CONFIG_PATH/${name}/${name}.cfg"
        [ -z "$netmode" ] && netmode="hidden"
        $ls_tap && [ "$netmode" != "tap" ] && continue

        printf "%20s %10.10s %20.20s %16.16s %s\n" \
                "$name" "$aflag" "$lflag" "$net" "$netmode"
    done
}
# ----

if [ `basename "$0"` = "vm-ls.sh" ] ; then
    [ "${vm_tools_initialized-NO}" != "YES" ] && {
        exec $(which vm) "ls" $@
        exit 1; }
    vm_ls $@
else
    true
fi
