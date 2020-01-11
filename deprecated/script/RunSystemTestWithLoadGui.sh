#!/bin/bash

#TESTNAME=StoreImmediate
TESTNAME=StoreToUart
WORKDIR="work/ModelSim/Processor"

# Move to project top directory
cd `dirname $0`
cd ..

echo "TESTNAME: ${TESTNAME}"
cd ${WORKDIR}

vsim SystemTestWithLoad -gui  -do ../../../../cpu/test/SystemTestWithLoad/vsim.macro -lib SystemTestWithLoad \
    -G INITIAL_MEMORY_PATH="../../../../firmware/build/${TESTNAME}.txt" \
    -G TRACE_PATH="../../../../work/Trace/cpu/${TESTNAME}.gui.trace.hjson" \
    -G ENABLE_FINISH=0 \
    -G ENABLE_DUMP_MEMORY=0 \
    -G MEMORY_DUMP_DIR="DUMMY"