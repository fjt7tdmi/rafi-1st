#!/bin/bash

# Move to project top directory
cd `dirname $0`
cd ..

python ./tool/MetaBuild.py \
    -i module/DivUnit/metabuild.json \
    -i module/MulUnit/metabuild.json \
    -i module/Uart/metabuild.json \
    -i cpu/metabuild.json \
    -i cpu/src/FetchUnit/metabuild.json \
    -i cpu/src/LoadStoreUnit/metabuild.json \
    -i firmware/metabuild.json \
    -o build.ninja
