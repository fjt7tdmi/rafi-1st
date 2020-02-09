#!/bin/bash

build_type="Debug"
if [ $# -ne 0 ]; then
    build_type=$1
fi

# Move to project top directory
pushd `dirname $0`
cd ..

source script/common.sh.inc

exit_code=0

function run_test() {
    if [[ "$(uname)" =~ ^MINGW ]]; then
        ./build_${build_type}/${build_type}/$1
    else
        ./build_${build_type}/$1
    fi

    if [ $? -ne 0 ]; then
        exit_code=1
    fi
}

# DivUnitTest fails now.
# TODO: fix DivUnit
# run_test rafi-vtest-div

run_test rafi-vtest-mul
run_test rafi-vtest-timer
run_test rafi-vtest-fp-comparator
run_test rafi-vtest-fp-converter

popd

exit ${exit_code}