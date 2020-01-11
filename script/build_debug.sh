#!/bin/bash

exit_code="1"

# Move to project top directory
pushd `dirname $0`
source ./common.sh.inc
cd ..

export VERILATOR_ROOT=`pwd`/third_party/verilator

mkdir -p build_Debug
cd build_Debug

if [[ -v RAFI_WIN ]]; then
    cmake .. -DCMAKE_BUILD_TYPE=Debug -G "Visual Studio 16 2019" -A x64 && cmake --build . --config Debug
    exit_code="$?"
else
    cmake .. -DCMAKE_BUILD_TYPE=Debug -G Ninja && cmake --build . --config Debug
    exit_code=$?
fi

popd

exit ${exit_code}