#!/bin/bash

# Move to project top directory
pushd `dirname $0`
cd ../Modules/Timer

${VERILATOR_BASE}/verilator.exe --cc Timer.sv

popd
