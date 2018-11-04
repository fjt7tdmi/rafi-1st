#!/bin/bash

# Move to project top directory
pushd `dirname $0`
cd ..

source ./rafi-emu/script/common.sh.inc
${RAFI_PYTHON} ./tool/run_zephyr.py $@

popd
