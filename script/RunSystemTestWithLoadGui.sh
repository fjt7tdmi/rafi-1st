#!/bin/bash

#TESTNAME=StoreImmediate
TESTNAME=StoreToUart
WORKDIR="Work/ModelSim/Processor"

# Move to project top directory
cd `dirname $0`
cd ..

echo "TESTNAME: ${TESTNAME}"
cd ${WORKDIR}

vsim SystemTestWithLoad -gui  -do ../../../../Processor/Tests/SystemTestWithLoad/vsim.macro -lib SystemTestWithLoad \
    -G INITIAL_MEMORY_PATH="../../../../TargetPrograms/Outputs/${TESTNAME}.txt" \
    -G TRACE_PATH="../../../../Work/Trace/Processor/${TESTNAME}.gui.trace.hjson" \
    -G ENABLE_FINISH=0 \
    -G ENABLE_DUMP_MEMORY=0 \
    -G MEMORY_DUMP_DIR="DUMMY"
