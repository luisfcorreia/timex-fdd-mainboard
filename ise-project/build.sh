#!/bin/bash
set -o pipefail
MODULE=timex_mainboard

# cleanup
. ./clean.sh

xst -ifn $MODULE.xst -ofn $MODULE.srf
if [ $? -ne 0 ]; then
    echo "Error: xst failed"
    exit 1
fi

ngdbuild -p xc9572xl-vq64 $MODULE.ngc
if [ $? -ne 0 ]; then
    echo "Error: ngdbuild failed"
    exit 1
fi

cpldfit -p xc9572xl-10-vq64 $MODULE.ngd
if [ $? -ne 0 ]; then
    echo "Error: cpldfit failed"
    exit 1
fi

hprep6 -i $MODULE.vm6
if [ $? -ne 0 ]; then
    echo "Error: hprep6 failed"
    exit 1
fi

echo "#####"
stat -c "%n: %s bytes" $MODULE.jed
