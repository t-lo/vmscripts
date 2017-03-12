#!/bin/bash -ue
#
# 'vmscripts' low-level VM management scripts - prepare a VM to play well with
#   vmscripts
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
#
# VM preparation
#  The following changes will be made to the VM image:
#
# - Serial output:
#   in /etc/default/grub:
#    GRUB_TIMEOUT=1
#    GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,1152008n1"
#    GRUB_TERMINAL=serial
#    GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
#
#   then:
#    update-grub
#
#   in /etc/inittab:
#    T0:23:respawn:/sbin/getty -L ttyS0 115200 vt100
#
# - SSH id:
#    VM Root ssh ID will be newly generated and added to the VM's root account.
#    ssh-keygen -f .ssh/id_rsa
#    ssh-copy-id -i .ssh/id_rsa.pub -p $ssh_port root@localhost
#
# - mount the local export dir:
#   mount -t 9p -o trans=virtio export /<whereever> -oversion=9p2000.L,posixacl,cache=none


vmscripts_prereq="inactive"

prepare_usage() {
    echo " Usage:"
    echo "    vm prepare <name>  - prepare VM image for use with vmscripts."
}
# ----

vm_prepare() {
    echo "---------------------------------------"
    echo "           Starting up $vm_name"
    vm start "$vm_name" rw
    echo
    echo "---------------------------------------"
    echo "                SSH Setup"
    echo
    echo "Generating SSH key pair for $vm_name"
    mkdir -p "$vm_path/.ssh"
    chmod 700 "$vm_path/.ssh"
    ssh-keygen -q -N "" -f "$vm_path/.ssh/id_rsa"
    echo
    echo " ### Installing SSH keys to $vm_name - this requires the VM's root password. ###"
    echo
    local ssh_port=$(vm ports fedora21 | grep '=> 22' | awk '{print $1}')
    echo -n "Waiting for $vm_name ssh to become available on host port $ssh_port ..."
    while true; do
        nc -w1 -i1 127.0.0.1 $ssh_port 2>/dev/null | grep -qi ssh && break
        echo -n '.'
    done
    ssh-copy-id -i "$vm_path/.ssh/id_rsa.pub"       \
                    -p $ssh_port                    \
                    -o UserKnownHostsFile=/dev/null \
                    -o StrictHostKeyChecking=no     \
                        root@localhost
    vm ssh "$vm_name" true || die "SSH setup failed for $vm_name"
    echo "            SSH Setup successful"
    echo "---------------------------------------"
    echo
    echo "   GRUB, serial console, and host export setup"
    echo
    vm ssh "$vm_name" \
        'echo "T0:23:respawn:/sbin/getty -L ttyS0 115200 vt100" >> /etc/inittab;
         echo "# vmscripts vm prepare settings" >> /etc/default/grub;
         echo "GRUB_TIMEOUT=1" >> /etc/default/grub;
         echo "GRUB_CMDLINE_LINUX_DEFAULT=\"console=tty0 console=ttyS0,1152008n1\"" >> /etc/default/grub;
         echo "GRUB_TERMINAL=serial" >> /etc/default/grub;
         echo "GRUB_SERIAL_COMMAND=\"serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1\"" >> /etc/default/grub;
         if which update-grub ; then
             update-grub ;
         else
             grub2-mkconfig -o /boot/grub2/grub.cfg;
         fi;
         mkdir -p /_host_root /_io;
         if which systemctl; then
             echo "hostroot /_host_root 9p x-systemd.automount,x-systemd.device-timeout=10,ro,dirsync,relatime,trans=virtio,version=9p2000.L,posixacl,cache=none 0 0" >> /etc/fstab;
             echo "io /_io 9p x-systemd.automount,x-systemd.device-timeout=10,rw,dirsync,relatime,trans=virtio,version=9p2000.L,posixacl,cache=none 0 0" >> /etc/fstab;
         else
             echo "hostroot /_host_root 9p ro,dirsync,relatime,trans=virtio,version=9p2000.L,posixacl,cache=none 0 0" >> /etc/fstab;
             echo "io /_io 9p rw,dirsync,relatime,trans=virtio,version=9p2000.L,posixacl,cache=none 0 0" >> /etc/fstab;
         fi;' \
        || die "Set-up failed for $vm_name"
    echo
    echo "      GRUB / serial, host export setup done"
    echo "---------------------------------------"
    echo
    echo "      Shutting down $vm_name"
    echo
    vm ssh "$vm_name" "poweroff"
    echo " All done."

}
# ----

if [ `basename "$0"` = "vm-prepare.sh" ] ; then
    [ "${vm_tools_initialized-NO}" != "YES" ] && {
        exec $(which vm) "prepare" $@
        exit 1; }
    vm_prepare $@
else
    true
fi
