#!/bin/bash

a2x --doctype manpage --format manpage README.asciidoc
gzip vm.1
