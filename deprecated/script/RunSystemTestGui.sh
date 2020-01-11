#!/bin/bash

if [ $# -ne 1 ]; then
    echo "usage: $0 <test_name>"
    exit 1
fi
TESTNAME=$1

WORKDIR="work/ModelSim/Processor"

# Move to project top directory
cd `dirname $0`
cd ..

echo "TESTNAME: ${TESTNAME}"
cd ${WORKDIR}

vsim SystemTest -gui -do ../../../../cpu/test/SystemTest/vsim.macro -lib SystemTest \
    -G INITIAL_MEMORY_PATH="../../../../firmware/build/${TESTNAME}.txt" \
    -G DUMP_PATH="../../../../work/Trace/cpu/${TESTNAME}.gui.trace.bin" \
    -G SIMULATION_CYCLE=32768 \
    -G ENABLE_DUMP_CSR=0 \
    -G ENABLE_DUMP_MEMORY=0 \
    -G ENABLE_FINISH=0
