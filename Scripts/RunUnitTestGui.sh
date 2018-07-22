#!/bin/bash

PROJECT=DivUnitTest
WORKDIR=Work/ModelSim/Modules/DivUnit
VSIM_MACRO=Modules/DivUnit/Tests/DivUnitTest/vsim.macro

# Move to project top directory
cd `dirname $0`
cd ..

echo "TESTNAME: ${TESTNAME}"
echo "PROJECT: ${PROJECT}"
cd ${WORKDIR}

vsim ${PROJECT} -gui -do ../../../../${VSIM_MACRO} -lib ${PROJECT}
