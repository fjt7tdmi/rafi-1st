#!/bin/bash

# Move to project top directory
pushd `dirname $0`
cd ..

mkdir -p work/verilator

verilator -Mdir work/verilator/test_Core --cc --top-module System \
    module/package/BasicTypes.sv \
    module/package/Rv32Types.sv \
    module/package/RvTypes.sv \
    module/Tlb/package/TlbTypes.sv \
    cpu/package/ProcessorTypes.sv \
    cpu/package/CacheTypes.sv \
    cpu/package/MemoryTypes.sv \
    cpu/package/OpTypes.sv \
    cpu/src/Decoder/package/Decoder.sv \
    cpu/src/LoadStoreUnit/package/LoadStoreUnitTypes.sv \
    module/DivUnit/src/DivUnit.sv \
    module/MulUnit/src/MulUnit.sv \
    module/Memory/BlockRam.sv \
    module/Memory/FlipFlopCam.sv \
    module/Memory/InternalMemory.sv \
    module/Memory/InternalSdram.sv \
    module/Memory/SdramController.sv \
    module/Tlb/Tlb.sv \
    module/Tlb/TlbReplacer.sv \
    module/Reset/ResetSequencer.sv \
    module/Uart/src/UartInput.sv \
    module/Uart/src/UartTx.sv \
    cpu/src/FetchUnit/FetchUnit.sv \
    cpu/src/FetchUnit/FetchUnitIF.sv \
    cpu/src/FetchUnit/ICacheInvalidater.sv \
    cpu/src/FetchUnit/ICacheReplacer.sv \
    cpu/src/LoadStoreUnit/DCacheReplacer.sv \
    cpu/src/LoadStoreUnit/LoadStoreUnitIF.sv \
    cpu/src/LoadStoreUnit/LoadStoreUnit.sv \
    cpu/src/MemoryAccessArbiter/MemoryAccessArbiter.sv \
    cpu/src/MemoryAccessArbiter/MemoryAccessArbiterIF.sv \
    cpu/src/BypassLogic.sv \
    cpu/src/BypassLogicIF.sv \
    cpu/src/ControlStatusRegister.sv \
    cpu/src/ControlStatusRegisterIF.sv \
    cpu/src/DecodeStage.sv \
    cpu/src/DecodeStageIF.sv \
    cpu/src/ExecuteStage.sv \
    cpu/src/ExecuteStageIF.sv \
    cpu/src/FetchStage.sv \
    cpu/src/FetchStageIF.sv \
    cpu/src/MemoryAccessStage.sv \
    cpu/src/MemoryAccessStageIF.sv \
    cpu/src/PipelineController.sv \
    cpu/src/PipelineControllerIF.sv \
    cpu/src/RegFile.sv \
    cpu/src/RegFileIF.sv \
    cpu/src/RegReadStage.sv \
    cpu/src/RegReadStageIF.sv \
    cpu/src/RegWriteStage.sv \
    cpu/src/System.sv \
    cpu/src/Core.sv

verilator -Mdir work/verilator/test_Timer --cc \
    module/Timer/Timer.sv

popd
