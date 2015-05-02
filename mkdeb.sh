#!/bin/bash
#
# Build "binary" vmscripts package.
#
# Requires 'mktemp, 'fakeroot', and 'dpkg-deb' command line tools in order 
#  to work.
#

function grok_version() {
    local changelog="$1"
    grep -m 1 -E '^[^ ]+' $changelog | sed 's/.*(\([-a-zA-Z0-9.]\+\)).*/\1/'
}
# ----

function grok_pkgname() {
    local changelog="$1"
    grep -m 1 -E '^[^ ]+' $changelog | sed 's/^\([a-zA-Z0-9_]\+\) .*/\1/'
}
# ----

function grok_arch() {
    local control="$1"
    grep -m 1 -E '^Architecture:' $control | cut -f2 -d " "
}
# ----

function mk_pkgdir() {
    local arch="`grok_arch DEBIAN/control`"
    local ver="`grok_version DEBIAN/changelog`"
    local pkg="`grok_pkgname DEBIAN/changelog`"
    [ -z "$arch" -o -z "$ver" -o -z "$pkg" ] && {
        echo "Error parsing DEBIAN/control or DEBIAN/changelog"
        exit 1; }

    local builddir="`mktemp -d`"
    [ -z "$builddir" ] && {
        echo "ERROR creating temporary build directors. stop."
        exit 1; }
    trap "rm -rf $builddir" exit

    pkgdir="$builddir/${pkg}_${ver}"
    mkdir "$pkgdir"
    echo "Building in $pkgdir"

    cp -R DEBIAN "$pkgdir"
    sed -i "s/%VERSION%/$ver/" $pkgdir/DEBIAN/control
}
# ----

function build_pkg() {
    filelist="$1"

    [ -f "$filelist" ] || {
        echo
        echo "Usage: $0 <file-list>"
        echo "          <file-list>: A file containing" 
        echo "                          'src-file dest-dir/' "
        echo "                       tuples of files to install, one per line,"
        echo "                       separated by spaces."
        echo
        exit 1
    }

    local pkgdir=""; export pkgdir
    mk_pkgdir

    echo "Copying files."
    cat $filelist | while read src dest; do
        [ -z "$src" -o -z "$dest" ] && continue
        mkdir -p $pkgdir/$dest
        cp $src $pkgdir/$dest
    done

    echo "Creating package."
    fakeroot "/bin/bash" -c "dpkg-deb --build \"$pkgdir\" ./"
}
# ----

[ `basename "$0"` = "mkdeb.sh" ] && {
    cd "`dirname $0`"
    build_pkg vmscripts.files 
}
