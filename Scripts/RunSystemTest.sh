#!/bin/bash

OPTION=""
if [ $# -ge 1 ]; then
    OPTION="-f $1"
else
    OPTION="-f rv*"
fi

# Move to project top directory
cd `dirname $0`
cd ..

python ./Tools/RunTestOnPc.py -s -i ./TargetPrograms/TestConfig.json ${OPTION}
