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

mkdir -p build_Release/Release
cd build_Release

if [[ -v RAFI_WIN ]]; then
    cmake .. -DCMAKE_BUILD_TYPE=Release -G "Visual Studio 16 2019" -A x64 && cmake --build . --parallel --config Release
    exit_code="$?"
else
    cmake .. -DCMAKE_BUILD_TYPE=Release -G Ninja && cmake --build . --parallel --config Release
    exit_code="$?"
fi

popd

exit ${exit_code}
