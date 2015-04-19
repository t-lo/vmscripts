#!/bin/bash
# shut down kvm TAP host IF

if="$1"
cd $(dirname ${BASH_SOURCE[0]})
source start.sh

[ -z "$if" ] && {
    echo “$0 $name ERROR: no interface specified”
    exit 1; }

[ "$if" != "$name" ] && {
    echo "$0 $name ERROR: unknwon interface $if (I only know $name)"
    exit 1 ; }

# take the if interface down along with its bridge
ip link set dev "$if" down
