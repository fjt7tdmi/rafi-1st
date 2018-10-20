#!/bin/bash

# Move to project top directory
pushd `dirname $0`
cd ..

mkdir -p work/verilator

verilator -Mdir work/verilator/test_Core --cc --top-module Core \
    Modules/Packages/BasicTypes.sv \
    Modules/Packages/Rv32Types.sv \
    Modules/Packages/RvTypes.sv \
    Modules/Tlb/Packages/TlbTypes.sv \
    Processor/Packages/ProcessorTypes.sv \
    Processor/Packages/CacheTypes.sv \
    Processor/Packages/MemoryTypes.sv \
    Processor/Packages/OpTypes.sv \
    Processor/Sources/Decoder/Packages/Decoder.sv \
    Processor/Sources/LoadStoreUnit/Packages/LoadStoreUnitTypes.sv \
    Modules/DivUnit/Sources/DivUnit.sv \
    Modules/MulUnit/Sources/MulUnit.sv \
    Modules/Memory/BlockRam.sv \
    Modules/Memory/FlipFlopCam.sv \
    Modules/Memory/InternalMemory.sv \
    Modules/Memory/InternalSdram.sv \
    Modules/Memory/SdramController.sv \
    Modules/Tlb/Tlb.sv \
    Modules/Tlb/TlbReplacer.sv \
    Modules/Reset/ResetSequencer.sv \
    Modules/Uart/Sources/UartInput.sv \
    Modules/Uart/Sources/UartTx.sv \
    Processor/Sources/FetchUnit/FetchUnit.sv \
    Processor/Sources/FetchUnit/FetchUnitIF.sv \
    Processor/Sources/FetchUnit/ICacheInvalidater.sv \
    Processor/Sources/FetchUnit/ICacheReplacer.sv \
    Processor/Sources/LoadStoreUnit/DCacheReplacer.sv \
    Processor/Sources/LoadStoreUnit/LoadStoreUnitIF.sv \
    Processor/Sources/LoadStoreUnit/LoadStoreUnit.sv \
    Processor/Sources/MemoryAccessArbiter/MemoryAccessArbiter.sv \
    Processor/Sources/MemoryAccessArbiter/MemoryAccessArbiterIF.sv \
    Processor/Sources/BypassLogic.sv \
    Processor/Sources/BypassLogicIF.sv \
    Processor/Sources/ControlStatusRegister.sv \
    Processor/Sources/ControlStatusRegisterIF.sv \
    Processor/Sources/DecodeStage.sv \
    Processor/Sources/DecodeStageIF.sv \
    Processor/Sources/ExecuteStage.sv \
    Processor/Sources/ExecuteStageIF.sv \
    Processor/Sources/FetchStage.sv \
    Processor/Sources/FetchStageIF.sv \
    Processor/Sources/MemoryAccessStage.sv \
    Processor/Sources/MemoryAccessStageIF.sv \
    Processor/Sources/PipelineController.sv \
    Processor/Sources/PipelineControllerIF.sv \
    Processor/Sources/RegFile.sv \
    Processor/Sources/RegFileIF.sv \
    Processor/Sources/RegReadStage.sv \
    Processor/Sources/RegReadStageIF.sv \
    Processor/Sources/RegWriteStage.sv \
    Processor/Sources/Core.sv

verilator -Mdir work/verilator/test_Timer --cc \
    Modules/Timer/Timer.sv

popd
