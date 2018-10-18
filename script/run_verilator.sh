#!/bin/bash

# Move to project top directory
pushd `dirname $0`
cd ../Modules/Timer

verilator --cc Timer.sv

popd
