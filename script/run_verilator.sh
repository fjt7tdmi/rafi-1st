#!/bin/bash

# Move to project top directory
pushd `dirname $0`
cd ..

mkdir -p work/verilator

verilator -Mdir work/verilator/test_Core --cc \
    Modules/Packages/BasicTypes.sv \
    Modules/Packages/Rv32Types.sv \
    Modules/Packages/RvTypes.sv \
    Modules/Tlb/Packages/TlbTypes.sv \
    Processor/Packages/ProcessorTypes.sv \
    Processor/Packages/CacheTypes.sv \
    Processor/Packages/MemoryTypes.sv \
    Processor/Packages/OpTypes.sv \
    Processor/Packages/TraceTypes.sv \
    Processor/Sources/Decoder/Packages/Decoder.sv \
    Processor/Sources/LoadStoreUnit/Packages/LoadStoreUnitTypes.sv

verilator -Mdir work/verilator/test_Timer --cc \
    Modules/Timer/Timer.sv

popd
