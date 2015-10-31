#!/bin/bash -ue
#
# 'vmscripts' low-level VM management scripts - VM creator
#
# Copyright © 2015 Thilo Fromm. Released under the terms of the GNU GPL v3.
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


vmscripts_prereq="name"

# the options, including their respective defaults
disk_size="4G"
disk_image=""
iso_image=""
move=false
mem="512M"
cpus="1"
net_mode="hidden" # hidden, tap
net="172.16.10.0/24"
forward_ports="22,25,80"

creat_usage () {
    echo " Usage:"
    echo "  vm creat <name> [<optional arguments>] - Create new VM '<name>'"
    echo
    echo " Optional arguments include:"
    echo
    echo "  -d|--disk <path-to-image>      Copy pre-existing harddisk image instead of creating a new empty volume."
    echo "  -s|--disk-size <size>          Size of the harddisk volume (may be followed by K, M, G or T)"
    echo "                                  to be created for the new VM."
    echo "                                  Default: $disk_size"
    echo "  -i|--iso <path-to-iso-image>   Path to an ISO image to use with the VM. The image will be copied."
    echo "  -M|--move                      Move source disk image and ISO instead of copying."
    echo "  -m|--mem <mem-size>            Amount of memory (followed by M or G)." 
    echo "                                  Default: $mem"
    echo "  -c|--cpus <nr-of-cpus>         Virtual CPUs count."
    echo "                                  Default: $cpus"
    echo "  -N|--net-mode <hidden|tap>     Networking mode."
    echo "                 hidden           No host-visible network devices; VM ports need to be forwarded (see -p)."
    echo "                 tap              VM uses a TAP device on the host. Starting the VM will require root privileges."
    echo "                                  Default: $net_mode"
    echo "  -n|--net <internal-network>    VM-internal network (IP/MASK)."
    echo "                                  Default: $net"
    echo "  -p|--ports <forwarded-ports>   List of ports forwarded to host ports in 'hidden' network mode,"
    echo "                                 separated by comma."
    echo "                                  Default '$forward_ports')"
}
# ----

creat_complete() {
    local cword="$1"; shift
    [ $cword -le 2 ] && return

    local words=( $@ )
    local opts="--iso --disk --disk-size --move --mem --cpus --net-mode --net --ports"
    local cur="${words[$cword]-}"
    local prev="${words[$((cword-1))]-}"


    # auto-complete options with the default settings
    case $prev in
        --iso)          echo "---DEFAULT---";; # complete filenames
        --disk)         echo "---DEFAULT---";; # complete filenames
        --disk-size)    echo -n "$disk_size";;
        --mem)          echo -n "$mem";;
        --cpus)         echo -n "$cpus";;
        --net-mode)     echo -n "$net_mode";;
        --net)          echo -n "$net";;
        --ports)        echo -n "$forward_ports";;
        *)              compgen -W "${opts}" -- $cur
    esac
}
# ----

image_and_iso() {
    local name="$1"
    local move="$2"
    local disk_size="$3"
    local disk_image="$4"
    local iso_image="$5"

    local op="cp"
    $move && op="mv"

    [ -e "$vm_path" ] && \
        die "The path '$vm_path' already exists. Remove it (vm purge ${name}) or choose a different name."

    mkdir "$vm_path"

    local img="$vm_path/${name}.img"
    if [ -e "$disk_image" ] ; then
        $op -v "$disk_image" "$img"
    else
        qemu-img create -f raw "$img" "$disk_size"
    fi

    img="$vm_path/${name}.iso"
    if [ -e "$iso_image" ] ; then
        $op -v "$iso_image" "$img"
    fi
}
# ----

write_config() {
    echo "$1=\"$2\"" >> "$vm_config"
}
# ----

vm_creat() {
    local opts
    opts=$(getopt -o i:d:s:Mm:c:N:n:p: \
                        -l "iso:,disk:,disk-size:,move,mem:,cpus:,net-mode:,net:,ports:" \
                        -n "vm creat" -- "$@")
    arg=""; name=""
    for o in $opts; do
        # set argument of an option
        [ -n "$arg" ] && {
            eval $arg="$o"; arg=""
            continue
        }

        # iterate options
        case $o in
            -i|--iso)       arg='iso_image';;
            -d|--disk)      arg='disk_image';;
            -s|--disk-size) arg='disk_size';;
            -m|--mem)       arg='mem';;
            -M|--move)      move=true;;
            -c|--cpus)      arg='cpus';;
            -N|--net-mode)  arg='net_mode';;
            -n|--net)       arg='net';;
            -p|--ports)     arg='forward_ports';;
            --)             arg="name";;
        esac
    done

    [ -z "$name" ] && usage "This command takes a mandatory <name> argument."

    image_and_iso "$name" "$move" "$disk_size" "$disk_image" "$iso_image"

    rm -f "$vm_config"
    write_config "net" "$net"
    write_config "netmode" "$net_mode"
    write_config "cpu" "$cpus"
    write_config "mem" "$mem"
    write_config "forward_ports" "${forward_ports//,/ }"

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
