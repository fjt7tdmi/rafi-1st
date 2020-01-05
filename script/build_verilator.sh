#!/bin/bash

exit_code="1"

# Move to project top directory
pushd `dirname $0`
source ./common.sh.inc
cd ../third_party/verilator

export VERILATOR_ROOT=`pwd`

autoconf
./configure CFLAGS="-I/usr/include" CPPFLAGS="-I/usr/include"
make -j${RAFI_NUM_CPU}
exit_code="$?"

popd

exit ${exit_code}
