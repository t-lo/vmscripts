#!/bin/bash

# Settings

       net="172.16.10.4/30" # host is first, VM is second IP in transfer net
       cpu="1"
  hmp_port="12345"
       mem="512M"
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
# - SSH id:
#    ssh-copy-id -i .ssh/id_rsa.test_vm.pub root@<ip address>
#    ssh-copy-id -i .ssh/id_rsa.test_vm.pub user@<ip address>
#
# - mount the local export dir:
#   mount -t 9p -o trans=virtio export /<whereever> -oversion=9p2000.L,posixacl,cache=loose
#   (check mtab entry; move to fstab)
# ----


# Globals

script_dir=`cd $(dirname ${BASH_SOURCE[0]}); pwd`
      name="$(basename "$script_dir")"
disk_image="$script_dir/${name}.raw"
 iso_image="$script_dir/${name}.iso"

# this dir is exported to the VM
export_dir="$(cd "$script_dir/../"; pwd)"

   pidfile="$script_dir/$name.pid"
   logfile="$script_dir/$name.log"

    net_up="$script_dir/up.sh"
    net_dn="$script_dir/down.sh"
# ----

vm_ssh() {
    ssh -i "$script_dir/.ssh/id_rsa"           \
               -o UserKnownHostsFile=/dev/null \
               -o StrictHostKeyChecking=no     \
               -o ConnectTimeout=5             \
               -o TCPKeepAlive=yes             \
               -o LogLevel=quiet               \
               -q                              \
                "$@"
}
# ----

vm_scp() {
    scp -i "$script_dir/.ssh/id_rsa"           \
               -o UserKnownHostsFile=/dev/null \
               -o StrictHostKeyChecking=no     \
               -o ConnectTimeout=5             \
               -o TCPKeepAlive=yes             \
               -o LogLevel=quiet               \
               -q                              \
                "$@"
}
# ----

tune_kvm_module() {
    local modname=""

    grep -q 'vmx' /proc/cpuinfo && modname="kvm-intel"
    grep -q 'svm' /proc/cpuinfo && modname="kvm-amd"

    [ -z "$modname" ] && {
        echo "Unable to determine virtualization hardware." 
        echo "Nested virtualization (i.e. 'intranet') may not work."
        return
    }

    # will only work while kvm is not in use; needs to be done only once
    rmmod $modname >/dev/null 2>&1 && modprobe $modname nested=1
}
# ----

grok_qemu() {
    local qemu="`which qemu-system-x86_64 2>/dev/null`"
    [ -z "$qemu" ] && qemu="`which qemu-kvm 2>/dev/null`"
    [ -z "$qemu" ] && qemu="`which kvm 2>/dev/null`"
    echo "$qemu"
}
# ----

ip_forward_and_nat() {
    local onoff="$1"
    local gw_if=`route -n | awk '/^0.0.0.0/ { print $8; }'`

    if $onoff; then
        [ -n "$gw_if" ] &&                                      \
            {   echo " NOTE: will NAT all connections going through $gw_if"
                iptables --table nat --append POSTROUTING       \
                                    --out-interface $gw_if -j MASQUERADE; }
        iptables  --insert FORWARD --in-interface ${name}  -j ACCEPT
        sysctl -q -w net.ipv4.ip_forward=1
    else 
        [ -n "$gw_if" ] && iptables --table nat --delete POSTROUTING     \
                                        --out-interface $gw_if -j MASQUERADE
        iptables  --delete FORWARD --in-interface ${name}  -j ACCEPT
    fi
}
# ----

start_vm() {

    local immutable="-snapshot"
    local nogfx="-nographic"

    echo "$@" | grep -q "rw" && immutable=""
    echo "$@" | grep -q "gfx" && nogfx=""

    kill -s 0 $(cat "$pidfile" 2>/dev/null) 2>/dev/null && {
        echo ""
        echo "VM $name already running"
        echo ""
        return 1; }
    rm -f "$pidfile"

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

    # prepare forwarding script to be executed in the screen session
    local ipt_script=`mktemp`
    trap "rm -f '$ipt_script'" EXTI
    declare -f ip_forward_and_nat > "$ipt_script"
    declare -f tune_kvm_module >> "$ipt_script"
    echo "name=\"$name\"" >> "$ipt_script"
    echo '$1 && tune_kvm_module' >> "$ipt_script"
    echo 'ip_forward_and_nat $1' >> "$ipt_script"
    chmod 755 "$ipt_script"

    local sudo=""
    [ "$(id -un)" != "root" ] && sudo=sudo
    screen -S "$name"       \
        $sudo bash -c "
            $ipt_script true ;
            $qemu                                                                   \
                -monitor telnet:127.0.0.1:$hmp_port,server,nowait,nodelay           \
                -pidfile \"$pidfile\"                                               \
                -m \"$mem\"                                                         \
                -rtc base=utc                                                       \
                -smp \"$cpu\"                                                       \
                -cpu host                                                           \
                $nogfx                                                              \
                -virtfs local,id=\"export\",path=\"$export_dir\",security_model=passthrough,mount_tag=export \
                -enable-kvm	                                                        \
                -machine pc,accel=kvm                                               \
                -net nic,model=virtio,vlan=0                                        \
                -net tap,vlan=0,ifname=$name,script=\"$net_up\",downscript=\"$net_dn\"  \
                -boot cdn                                                           \
                -drive file=$disk_image,if=virtio,index=0,media=disk                \
                $cdrom                                                              \
                $immutable ;
            $ipt_script false ;
            rm -f \"$pidfile\" ; "
}
# ----

poweroff() {
    local if="$1"
    (sleep 1; echo "quit") | nc 127.0.0.1 "$hmp_port"
    rm -f "$pidfile"
}
# ----

[ `basename "$0"` = "start.sh" ] && {
    case $1 in
        *off)   poweroff $@ ;;
        *)      start_vm $@ ;;
    esac
}
