#!/bin/bash

if [ $# -ne 1 ]; then
    echo "usage: $0 <test_name>"
    exit 1
fi
TESTNAME=$1

WORKDIR="Work/ModelSim/Processor"

# Move to project top directory
cd `dirname $0`
cd ..

echo "TESTNAME: ${TESTNAME}"
cd ${WORKDIR}

vsim SystemTest -gui -do ../../../../Processor/Tests/SystemTest/vsim.macro -lib SystemTest \
    -G INITIAL_MEMORY_PATH="../../../../TargetPrograms/Outputs/${TESTNAME}.txt" \
    -G DUMP_PATH="../../../../Work/Trace/Processor/${TESTNAME}.gui.trace.bin" \
    -G SIMULATION_CYCLE=32768 \
    -G ENABLE_DUMP_CSR=0 \
    -G ENABLE_DUMP_MEMORY=0 \
    -G ENABLE_FINISH=0
