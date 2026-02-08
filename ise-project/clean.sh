#!/bin/bash
# cleanup
set -o pipefail
MODULE=timex_mainboard
shopt -s extglob
rm -rf !(build.sh|clean.sh|$MODULE.prj|$MODULE.ucf|$MODULE.xst|$MODULE.v)
