#!/bin/bash

# Move to project top directory
cd `dirname $0`
cd ..

python ./Tools/MetaBuild.py \
    -i Modules/DivUnit/metabuild.json \
    -i Modules/MulUnit/metabuild.json \
    -i Modules/Uart/metabuild.json \
    -i Processor/metabuild.json \
    -i Processor/Sources/FetchUnit/metabuild.json \
    -i Processor/Sources/LoadStoreUnit/metabuild.json \
    -i TargetPrograms/metabuild.json \
    -o build.ninja
