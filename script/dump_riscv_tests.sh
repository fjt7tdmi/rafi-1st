#!/bin/bash

if [ $# -eq 0 ]; then
    echo "usage: $0 <test-name>"
    exit 1
fi

test_name=$1
build_type="Release"

# Move to project top directory
pushd `dirname $0`
cd ..

source script/common.sh.inc


if [[ "$(uname)" =~ ^MINGW ]]; then
    ./build_${build_type}/${build_type}/rafi-dump ./work/riscv-tests/${test_name}.tidx
else
    ./build_${build_type}/rafi-dump ./work/riscv-tests/${test_name}.tidx
fi

exit_code=$?

popd

exit ${exit_code}