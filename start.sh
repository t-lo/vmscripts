#!/bin/bash

# Settings
       net="172.16.10.0/24" # only matters inside of the VM (qemu user mode net)
       cpu="1"
       mem="512M"
       forward_ports="22 80"
# ----
#
# VM preparation
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
# ----


# Globals

script_dir=`cd $(dirname ${BASH_SOURCE[0]}); pwd`
      name="$(basename "$script_dir")"
disk_image="$script_dir/${name}.raw"
 iso_image="$script_dir/${name}.iso"

# this dir is exported to the VM
export_dir="$(cd "$script_dir/../"; pwd)"

   pidfile="$script_dir/${name}.pid"
   netfile="$script_dir/${name}.net"
   logfile="$script_dir/${name}.log"

    net_up="$script_dir/up.sh"
    net_dn="$script_dir/down.sh"

    # source network config if present
[ -f "$netfile" ] && source "$netfile"
# ----

tune_kvm_module() {
    local modname=""

    local sudo=""
    local user="$(id -un)"
    [ "$user" != "root" ] && sudo=sudo

    grep -q 'vmx' /proc/cpuinfo && modname="kvm-intel"
    grep -q 'svm' /proc/cpuinfo && modname="kvm-amd"

    [ -z "$modname" ] && {
        echo "Unable to determine virtualization hardware." 
        echo "Nested virtualization (i.e. 'intranet') may not work."
        return
    }

    local sysfs="/sys/module/${modname/-/_}/parameters/nested"
    [ "$(cat $sysfs)" != "Y" ] && {
        $sudo rmmod $modname >/dev/null 2>&1 \
            && $sudo modprobe $modname nested=1 ; }
}
# ----

grok_qemu() {
    local qemu="`which qemu-system-x86_64 2>/dev/null`"
    [ -z "$qemu" ] && qemu="`which qemu-kvm 2>/dev/null`"
    [ -z "$qemu" ] && qemu="`which kvm 2>/dev/null`"
    echo "$qemu"
}
# ----

grok_free_port() {
    local ignored_ports="$@"
    local start=1024
    local p=""
    {   netstat -ntpl 2>/dev/null   \
            | sed -n 's/.* [0-9.]\+:\([0-9]\+\) .*/\1/p'
        seq $start 65535
        for p in $ignored_ports; do echo $p; done
    } | sort -n | grep -A 130000 1024 | uniq -u | head -1
}
# ----

grok_ports() {
    local hmp=$(grok_free_port)
    echo "port_hmp=\"$hmp\"" > "$netfile"

    local acquired_ports="$hmp"
    local p=""
    local prev=""
    for p in $forward_ports; do
        [ -n "$prev" ] && echo -n "$prev,"
        local l=$(grok_free_port $acquired_ports)
        echo "port_$p=\"$l\"" >> "$netfile"
        prev="hostfwd=::$l-:$p"
        acquired_ports="$acquired_ports $l"
    done
    echo -n "$prev"
}
# ----

start_vm() {

    # command line options
    local immutable="-snapshot"
    local nogfx="-nographic"
    local detach=""

    echo "$@" | grep -q "rw" && immutable=""
    echo "$@" | grep -q "gfx" && nogfx=""
    echo "$@" | grep -q "detach" && detach="-d -m"

    [ -f "$pidfile" ] && {
        $sudo kill -s 0 $(cat "$pidfile" 2>/dev/null) 2>/dev/null && {
            echo ""
            echo "VM $name already running"
            echo ""
            return 1; }
        $sudo rm -f "$pidfile"
    }

    local qemu="`grok_qemu`"
    [ -z "$qemu" ] && {
        echo "ERROR: qemu not found"; exit 1; }

    local cdrom=""
    [ -e "$iso_image" ] && \
        cdrom="-drive file=$iso_image,if=ide,index=0,media=cdrom"

    [ -z "$immutable" ] && {
        echo
        echo "The VM image will be *mutable*, all changes will persist."
        echo ; }

    tune_kvm_module
    local hostfwd=`grok_ports`
    source "$netfile"

    screen $detach -A -S "$name" \
        bash -c "
            $qemu                                                                   \
                -monitor telnet:127.0.0.1:$port_hmp,server,nowait,nodelay           \
                -pidfile \"$pidfile\"                                               \
                -m \"$mem\"                                                         \
                -rtc base=utc                                                       \
                -smp \"$cpu\"                                                       \
                -cpu host                                                           \
                $nogfx                                                              \
                -virtfs local,id=\"export\",path=\"$export_dir\",security_model=none,mount_tag=export \
                -machine pc,accel=kvm                                               \
                -net nic,model=virtio,vlan=0                                        \
                -net user,vlan=0,net=$net,hostname=$name,$hostfwd                   \
                -boot cdn                                                           \
                -drive file=$disk_image,if=virtio,index=0,media=disk                \
                $cdrom                                                              \
                $immutable ;
            rm -f \"$pidfile\" \"$netfile\" ; "

    [ "$detach" != "" ] && {
        echo "-------------------------------------------"
        echo " The VM $name has been started and"
        echo " detached from this terminal. Run"
        echo "   screen -rd $name"
        echo " to attach to the VM."
        echo ; }
}
# ----

poweroff() {
    source "$netfile"
    (sleep 1; echo "quit") | nc 127.0.0.1 "$port_hmp"
    rm -f "$pidfile"
}
# ----

[ `basename "$0"` = "start.sh" ] && {
    cd $(dirname ${BASH_SOURCE[0]})
    case $1 in
        *off)   poweroff $@ ;;
        *)      start_vm $@ ;;
    esac
}
