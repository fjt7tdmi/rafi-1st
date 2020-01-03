#!/bin/bash

# Move to project top directory
pushd `dirname $0`
cd ..

mkdir -p work/verilator

verilator -Mdir work/verilator/test_Core --cc --trace --top-module Core \
    src/hw/module/package/BasicTypes.sv \
    src/hw/module/package/Rv32Types.sv \
    src/hw/module/package/RvTypes.sv \
    src/hw/module/Tlb/package/TlbTypes.sv \
    src/hw/cpu/package/ProcessorTypes.sv \
    src/hw/cpu/package/CacheTypes.sv \
    src/hw/cpu/package/MemoryTypes.sv \
    src/hw/cpu/package/OpTypes.sv \
    src/hw/cpu/src/Decoder/package/Decoder.sv \
    src/hw/cpu/src/LoadStoreUnit/package/LoadStoreUnitTypes.sv \
    src/hw/module/DivUnit/src/DivUnit.sv \
    src/hw/module/MulUnit/src/MulUnit.sv \
    src/hw/module/Memory/BlockRam.sv \
    src/hw/module/Memory/FlipFlopCam.sv \
    src/hw/module/Tlb/Tlb.sv \
    src/hw/module/Tlb/TlbReplacer.sv \
    src/hw/module/Reset/ResetSequencer.sv \
    src/hw/cpu/src/FetchUnit/FetchUnit.sv \
    src/hw/cpu/src/FetchUnit/FetchUnitIF.sv \
    src/hw/cpu/src/FetchUnit/ICacheInvalidater.sv \
    src/hw/cpu/src/FetchUnit/ICacheReplacer.sv \
    src/hw/cpu/src/LoadStoreUnit/DCacheReplacer.sv \
    src/hw/cpu/src/LoadStoreUnit/LoadStoreUnitIF.sv \
    src/hw/cpu/src/LoadStoreUnit/LoadStoreUnit.sv \
    src/hw/cpu/src/BusAccessUnit/BusAccessUnit.sv \
    src/hw/cpu/src/BusAccessUnit/BusAccessUnitIF.sv \
    src/hw/cpu/src/BypassLogic.sv \
    src/hw/cpu/src/BypassLogicIF.sv \
    src/hw/cpu/src/ControlStatusRegister.sv \
    src/hw/cpu/src/ControlStatusRegisterIF.sv \
    src/hw/cpu/src/DecodeStage.sv \
    src/hw/cpu/src/DecodeStageIF.sv \
    src/hw/cpu/src/ExecuteStage.sv \
    src/hw/cpu/src/ExecuteStageIF.sv \
    src/hw/cpu/src/FetchStage.sv \
    src/hw/cpu/src/FetchStageIF.sv \
    src/hw/cpu/src/MemoryAccessStage.sv \
    src/hw/cpu/src/MemoryAccessStageIF.sv \
    src/hw/cpu/src/PipelineController.sv \
    src/hw/cpu/src/PipelineControllerIF.sv \
    src/hw/cpu/src/RegFile.sv \
    src/hw/cpu/src/RegFileIF.sv \
    src/hw/cpu/src/RegReadStage.sv \
    src/hw/cpu/src/RegReadStageIF.sv \
    src/hw/cpu/src/RegWriteStage.sv \
    src/hw/cpu/src/Core.sv

verilator -Mdir work/verilator/test_DivUnit --cc --trace --top-module DivUnit32 \
    src/hw/module/DivUnit/src/DivUnit.sv \
    src/hw/module/DivUnit/src/DivUnit32.sv

verilator -Mdir work/verilator/test_Timer --cc  --trace --top-module Timer \
    src/hw/module/Timer/Timer.sv

popd
