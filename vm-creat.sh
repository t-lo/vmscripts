#!/bin/bash
#
# 'vmscripts' low-level VM management scripts - VM creator
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

# Create a VM (i.e. add it to vmtools)
# Properties from cmdl. arguments:
#  1. name
#  2. disk size or existing image
#  3. ISO image
#  4. MEM size
#  5. Nr. of CPUs
#  6. internal network + mask
#  7. forwarded ports (default: 22, 25, 80)
# -provide defaults, generate .cfg
# -create / move existing image in .vmscripts/<name>/<name>.raw, .iso

#
# VM preparation
#  This could be done with a linux VM after creation (may be automated):
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
#
# ----
#  Ideas
#  - deb / rpm package generator w/ centralized scripts
#  - system wide and per-user configurations and images
#  - automated VM preparation (needs root pw, VM must boot via DHCP)
# ----


