#!/bin/bash

# Move to project top directory
pushd `dirname $0`
cd ..

source ./rafi-emu/script/common.sh.inc
${RAFI_PYTHON} ./tool/diff_zephyr.py -i ./rafi-emu/test/zephyr.config.json $@

popd
