#!/bin/bash

# Move to project top directory
pushd `dirname $0`
cd ..

source script/common.sh.inc

${RAFI_PYTHON} ./tool/run_riscv_tests.py --sim -i ./test/sim_riscv_tests.config.json $@
exit_code=$?

popd

exit ${exit_code}