#!/bin/bash

build_type="Debug"
if [ $# -ne 0 ]; then
    build_type=$1
fi

# Move to project top directory
pushd `dirname $0`
cd ..

source script/common.sh.inc

function run_test() {
    if [[ "$(uname)" =~ ^MINGW ]]; then
        ./build_${build_type}/${build_type}/$1
    else
        ./build_${build_type}/$1
    fi

    if [ $? -ne 0 ]; then
        exit $?
    fi
}

# run_test rafi-vtest-div
run_test rafi-vtest-fp-converter
run_test rafi-vtest-fp32-comparator
run_test rafi-vtest-fp32-mul-add
run_test rafi-vtest-fp32-div
run_test rafi-vtest-fp32-sqrt
run_test rafi-vtest-fp64-comparator
run_test rafi-vtest-fp64-mul-add
run_test rafi-vtest-fp64-div
run_test rafi-vtest-fp64-sqrt
run_test rafi-vtest-mul
run_test rafi-vtest-sqrt
run_test rafi-vtest-timer
run_test rafi-vtest-tlb

popd

exit ${exit_code}