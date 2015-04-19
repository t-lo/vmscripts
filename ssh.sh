#!/bin/bash

cd $(dirname ${BASH_SOURCE[0]})
source start.sh

ssh -i .ssh/id_rsa.test_vm root@172.16.10.2
