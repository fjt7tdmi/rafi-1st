#!/bin/bash

OPTION=""
if [ $# -ge 1 ]; then
    OPTION="-f $1"
fi

# Move to project top directory
cd `dirname $0`
cd ..

python ./Tools/RunTestOnPc.py -e -i ./TargetPrograms/TestConfig.json ${OPTION}
