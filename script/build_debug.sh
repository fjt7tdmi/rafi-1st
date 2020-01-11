#!/bin/bash

exit_code="1"

# Move to project top directory
pushd `dirname $0`
source ./common.sh.inc
cd ..

if [[ -v RAFI_WIN ]]; then
    export VERILATOR_ROOT=`pwd`/third_party/verilator
else
    export VERILATOR_ROOT=`pwd`/third_party/rafi-prebuilt-binary/verilator/Linux-x86_64
fi

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
