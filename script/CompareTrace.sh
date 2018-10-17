#!/bin/bash

if [ $# -ne 1 ]; then
    echo "usage: $0 <test_name>"
    exit 1
fi
TESTNAME=$1

# Move to project top directory
cd `dirname $0`
cd ..

echo "TESTNAME: ${TESTNAME}"

./rafi-emu/Release/PrintTrace.exe \
    ./Work/Trace/Emulator/${TESTNAME}.trace.bin > ./Work/Trace/Emulator/${TESTNAME}.trace.txt

./rafi-emu/Release/PrintTrace.exe \
    ./Work/Trace/Processor/${TESTNAME}.trace.bin > ./Work/Trace/Processor/${TESTNAME}.trace.txt

./rafi-emu/Release/CompareTrace.exe \
    --expect ./Work/Trace/Emulator/${TESTNAME}.trace.bin \
    --actual ./Work/Trace/Processor/${TESTNAME}.trace.bin
