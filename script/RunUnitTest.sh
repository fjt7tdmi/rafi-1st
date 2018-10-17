#!/bin/bash

PROJECT=DivUnitTest
WORKDIR=Work/ModelSim/Modules/DivUnit

# Move to project top directory
cd `dirname $0`
cd ..

echo "PROJECT: ${PROJECT}"
cd ${WORKDIR}
vsim ${PROJECT} -c -lib ${PROJECT} -do "run -all"
