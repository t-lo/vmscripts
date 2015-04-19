#!/bin/bash
# configure kvm TAP host IF

if="$1"
cd $(dirname ${BASH_SOURCE[0]})
source start.sh

[ -z "$if" ] && {
    echo “$0 $name ERROR: no interface specified”
    exit 1; }

[ "$if" != "$name" ] && {
    echo "$0 $name ERROR: unknwon interface $if (I only know $name)"
    exit 1 ; }

# max the MTU of the KVM iface
ip a a "$net" dev "$if"

# bring it up
ip link set mtu 65521 dev "$if" up
