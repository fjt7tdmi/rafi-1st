#!/bin/bash

# Move to project top directory
pushd `dirname $0`
cd ..

source ./rafi-emu/script/common.sh.inc
${RAFI_PYTHON} ./tool/run_diff.py -i ./rafi-emu/test/riscv_tests.config.json $@

popd
