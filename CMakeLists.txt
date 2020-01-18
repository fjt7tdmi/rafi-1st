cmake_minimum_required(VERSION 3.8)

project(Rafi)

enable_language(CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /MTd")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /MT")
endif()

# =========================================================================
# boost
#
find_package(Boost)
if (NOT ${Boost_FOUND})
    message(FATAL_ERROR "Cannot find boost.")
endif()

include_directories(${Boost_INCLUDE_DIRS})
link_directories(${Boost_LIBRARY_DIRS})

# =========================================================================
# verilator
#
find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})

# GoogleTest
set(GoogleTest_INCLUDE_DIRS "third_party/googletest/googletest/include")
if (MSVC)
    set(Socket_LIBRARIES "ws2_32")
    if (${CMAKE_BUILD_TYPE} MATCHES "Debug")
        set(GoogleTest_LIBRARIES "gtestd" "gtest_maind")
        set(GoogleTest_LIBRARY_DIRS "third_party/googletest/x64-Debug/lib/Debug")
    else()
        set(GoogleTest_LIBRARIES "gtest" "gtest_main")
        set(GoogleTest_LIBRARY_DIRS "third_party/googletest/x64-Release/lib/Release")
    endif()
else()
    set(Socket_LIBRARIES "")
    set(Boost_LIBRARIES "boost_program_options")
    set(FS_LIBRARIES "stdc++fs")

    set(GoogleTest_LIBRARIES "gtest" "gtest_main" "pthread")
    set(GoogleTest_LIBRARY_DIRS "third_party/googletest/build/lib")
endif()

include_directories(${GoogleTest_INCLUDE_DIRS})
link_directories(${GoogleTest_LIBRARY_DIRS})

# =========================================================================
# softfloat
#
set(Softfloat_INCLUDE_DIRS third_party/berkeley-softfloat-3/source/include third_party/berkeley-softfloat-3/source/RISCV src/lib/fp/include)

# =========================================================================
# librafi_common
#
add_library(librafi_common
    include/rafi/common.h
    include/rafi/common/BitField.h
    include/rafi/common/Decoder.h
    include/rafi/common/Macro.h
    include/rafi/common/OpApi.h
    include/rafi/common/OpTypes.h
    include/rafi/common/RvApi.h
    include/rafi/common/RvCsr.h
    include/rafi/common/RvPageTable.h
    include/rafi/common/RvTypes.h
    include/rafi/common/Util.h
    src/lib/common/Decoder.cpp
    src/lib/common/OpApi.cpp
    src/lib/common/RvApi.cpp
)

# =========================================================================
# librafi_fp
#
add_library(librafi_fp
    include/rafi/common.h
    include/rafi/fp.h
    include/rafi/common/BitField.h
    include/rafi/fp/FpApi.h
    include/rafi/fp/ScopedFpRound.h
    src/lib/fp/include/platform.h
    src/lib/fp/FpApi.cpp
    src/lib/fp/ScopedFpRound.cpp

    # berkeley-softfloat-3 include
    third_party/berkeley-softfloat-3/source/include/internals.h
    third_party/berkeley-softfloat-3/source/include/primitives.h
    third_party/berkeley-softfloat-3/source/include/primitiveTypes.h
    third_party/berkeley-softfloat-3/source/include/softfloat_types.h
    third_party/berkeley-softfloat-3/source/include/softfloat.h

    # berkeley-softfloat-3 primitive
    third_party/berkeley-softfloat-3/source/s_compare96M.c
    third_party/berkeley-softfloat-3/source/s_compare128M.c
    third_party/berkeley-softfloat-3/source/s_shortShiftLeft64To96M.c
    third_party/berkeley-softfloat-3/source/s_shortShiftLeftM.c
    third_party/berkeley-softfloat-3/source/s_shiftLeftM.c
    third_party/berkeley-softfloat-3/source/s_shortShiftRightM.c
    third_party/berkeley-softfloat-3/source/s_shortShiftRightJam64.c
    third_party/berkeley-softfloat-3/source/s_shortShiftRightJamM.c
    third_party/berkeley-softfloat-3/source/s_shiftRightJam32.c
    third_party/berkeley-softfloat-3/source/s_shiftRightJam64.c
    third_party/berkeley-softfloat-3/source/s_shiftRightJamM.c
    third_party/berkeley-softfloat-3/source/s_shiftRightM.c
    third_party/berkeley-softfloat-3/source/s_countLeadingZeros8.c
    third_party/berkeley-softfloat-3/source/s_countLeadingZeros16.c
    third_party/berkeley-softfloat-3/source/s_countLeadingZeros32.c
    third_party/berkeley-softfloat-3/source/s_countLeadingZeros64.c
    third_party/berkeley-softfloat-3/source/s_addM.c
    third_party/berkeley-softfloat-3/source/s_addCarryM.c
    third_party/berkeley-softfloat-3/source/s_addComplCarryM.c
    third_party/berkeley-softfloat-3/source/s_negXM.c
    third_party/berkeley-softfloat-3/source/s_sub1XM.c
    third_party/berkeley-softfloat-3/source/s_subM.c
    third_party/berkeley-softfloat-3/source/s_approxRecip_1Ks.c
    third_party/berkeley-softfloat-3/source/s_approxRecip32_1.c
    third_party/berkeley-softfloat-3/source/s_approxRecipSqrt_1Ks.c
    third_party/berkeley-softfloat-3/source/s_approxRecipSqrt32_1.c
    third_party/berkeley-softfloat-3/source/s_remStepMBy32.c

    # berkeley-softfloat-3 specialize
    third_party/berkeley-softfloat-3/source/RISCV/s_commonNaNToF64UI.c
    third_party/berkeley-softfloat-3/source/RISCV/s_f32UIToCommonNaN.c
    third_party/berkeley-softfloat-3/source/RISCV/s_propagateNaNF64UI.c
    third_party/berkeley-softfloat-3/source/RISCV/specialize.h
    third_party/berkeley-softfloat-3/source/RISCV/s_commonNaNToF32UI.c
    third_party/berkeley-softfloat-3/source/RISCV/s_f64UIToCommonNaN.c
    third_party/berkeley-softfloat-3/source/RISCV/s_propagateNaNF32UI.c
    third_party/berkeley-softfloat-3/source/RISCV/softfloat_raiseFlags.c

    # berkeley-softfloat-3 others
    third_party/berkeley-softfloat-3/source/s_roundToUI32.c
    third_party/berkeley-softfloat-3/source/s_roundMToUI64.c
    third_party/berkeley-softfloat-3/source/s_roundToI32.c
    third_party/berkeley-softfloat-3/source/s_roundMToI64.c
    third_party/berkeley-softfloat-3/source/s_normSubnormalF32Sig.c
    third_party/berkeley-softfloat-3/source/s_roundPackToF32.c
    third_party/berkeley-softfloat-3/source/s_normRoundPackToF32.c
    third_party/berkeley-softfloat-3/source/s_addMagsF32.c
    third_party/berkeley-softfloat-3/source/s_subMagsF32.c
    third_party/berkeley-softfloat-3/source/s_mulAddF32.c
    third_party/berkeley-softfloat-3/source/s_normSubnormalF64Sig.c
    third_party/berkeley-softfloat-3/source/s_roundPackToF64.c
    third_party/berkeley-softfloat-3/source/s_normRoundPackToF64.c
    third_party/berkeley-softfloat-3/source/s_addMagsF64.c
    third_party/berkeley-softfloat-3/source/s_subMagsF64.c
    third_party/berkeley-softfloat-3/source/s_mulAddF64.c
    third_party/berkeley-softfloat-3/source/s_mul64To128M.c
    third_party/berkeley-softfloat-3/source/softfloat_state.c
    third_party/berkeley-softfloat-3/source/ui32_to_f32.c
    third_party/berkeley-softfloat-3/source/ui32_to_f64.c
    third_party/berkeley-softfloat-3/source/ui64_to_f32.c
    third_party/berkeley-softfloat-3/source/ui64_to_f64.c
    third_party/berkeley-softfloat-3/source/i32_to_f32.c
    third_party/berkeley-softfloat-3/source/i32_to_f64.c
    third_party/berkeley-softfloat-3/source/i64_to_f32.c
    third_party/berkeley-softfloat-3/source/i64_to_f64.c
    third_party/berkeley-softfloat-3/source/f32_to_ui32.c
    third_party/berkeley-softfloat-3/source/f32_to_ui64.c
    third_party/berkeley-softfloat-3/source/f32_to_i32.c
    third_party/berkeley-softfloat-3/source/f32_to_i64.c
    third_party/berkeley-softfloat-3/source/f32_to_ui32_r_minMag.c
    third_party/berkeley-softfloat-3/source/f32_to_ui64_r_minMag.c
    third_party/berkeley-softfloat-3/source/f32_to_i32_r_minMag.c
    third_party/berkeley-softfloat-3/source/f32_to_i64_r_minMag.c
    third_party/berkeley-softfloat-3/source/f32_to_f64.c
    third_party/berkeley-softfloat-3/source/f32_roundToInt.c
    third_party/berkeley-softfloat-3/source/f32_add.c
    third_party/berkeley-softfloat-3/source/f32_sub.c
    third_party/berkeley-softfloat-3/source/f32_mul.c
    third_party/berkeley-softfloat-3/source/f32_mulAdd.c
    third_party/berkeley-softfloat-3/source/f32_div.c
    third_party/berkeley-softfloat-3/source/f32_rem.c
    third_party/berkeley-softfloat-3/source/f32_sqrt.c
    third_party/berkeley-softfloat-3/source/f32_eq.c
    third_party/berkeley-softfloat-3/source/f32_le.c
    third_party/berkeley-softfloat-3/source/f32_lt.c
    third_party/berkeley-softfloat-3/source/f32_eq_signaling.c
    third_party/berkeley-softfloat-3/source/f32_le_quiet.c
    third_party/berkeley-softfloat-3/source/f32_lt_quiet.c
    third_party/berkeley-softfloat-3/source/f32_isSignalingNaN.c
    third_party/berkeley-softfloat-3/source/f64_to_ui32.c
    third_party/berkeley-softfloat-3/source/f64_to_ui64.c
    third_party/berkeley-softfloat-3/source/f64_to_i32.c
    third_party/berkeley-softfloat-3/source/f64_to_i64.c
    third_party/berkeley-softfloat-3/source/f64_to_ui32_r_minMag.c
    third_party/berkeley-softfloat-3/source/f64_to_ui64_r_minMag.c
    third_party/berkeley-softfloat-3/source/f64_to_i32_r_minMag.c
    third_party/berkeley-softfloat-3/source/f64_to_i64_r_minMag.c
    third_party/berkeley-softfloat-3/source/f64_to_f32.c
    third_party/berkeley-softfloat-3/source/f64_roundToInt.c
    third_party/berkeley-softfloat-3/source/f64_add.c
    third_party/berkeley-softfloat-3/source/f64_sub.c
    third_party/berkeley-softfloat-3/source/f64_mul.c
    third_party/berkeley-softfloat-3/source/f64_mulAdd.c
    third_party/berkeley-softfloat-3/source/f64_div.c
    third_party/berkeley-softfloat-3/source/f64_rem.c
    third_party/berkeley-softfloat-3/source/f64_sqrt.c
    third_party/berkeley-softfloat-3/source/f64_eq.c
    third_party/berkeley-softfloat-3/source/f64_le.c
    third_party/berkeley-softfloat-3/source/f64_lt.c
    third_party/berkeley-softfloat-3/source/f64_eq_signaling.c
    third_party/berkeley-softfloat-3/source/f64_le_quiet.c
    third_party/berkeley-softfloat-3/source/f64_lt_quiet.c
    third_party/berkeley-softfloat-3/source/f64_isSignalingNaN.c
)

if (MSVC)
    target_compile_options(librafi_fp
        PUBLIC /wd"4101"
        PUBLIC /wd"4102"
        PUBLIC /wd"4146"
        PUBLIC /wd"4206"
        PUBLIC /wd"4244"
        PUBLIC /wd"4389"
        PUBLIC /wd"4701"
        PUBLIC /wd"4703"
        )
endif()

include_directories(librafi_fp include ${Softfloat_INCLUDE_DIRS})

# =========================================================================
# librafi_trace
#
add_library(librafi_trace
    include/rafi/trace.h
    include/rafi/trace/BinaryCycleBuilder.h
    include/rafi/trace/CycleTypes.h
    include/rafi/trace/Exception.h
    include/rafi/trace/GdbTraceReader.h
    include/rafi/trace/ICycle.h
    include/rafi/trace/ITraceReader.h
    include/rafi/trace/ITraceWriter.h
    include/rafi/trace/ILoggerTarget.h
    include/rafi/trace/Logger.h
    include/rafi/trace/LoggerConfig.h
    include/rafi/trace/TraceBinaryMemoryReader.h
    include/rafi/trace/TraceBinaryMemoryWriter.h
    include/rafi/trace/TraceBinaryReader.h
    include/rafi/trace/TraceBinaryWriter.h
    include/rafi/trace/TraceIndexReader.h
    include/rafi/trace/TraceIndexWriter.h
    include/rafi/trace/TraceJsonPrinter.h
    include/rafi/trace/TracePcPrinter.h
    include/rafi/trace/TraceTextPrinter.h
    include/rafi/trace/TraceTextReader.h
    src/lib/trace/BinaryCycle.cpp
    src/lib/trace/BinaryCycle.h
    src/lib/trace/BinaryCycleBuilder.cpp
    src/lib/trace/GdbCycle.cpp
    src/lib/trace/GdbCycle.h
    src/lib/trace/GdbTrace.cpp
    src/lib/trace/GdbTrace.h
    src/lib/trace/GdbTraceReader.cpp
    src/lib/trace/Logger.cpp
    src/lib/trace/TextCycle.cpp
    src/lib/trace/TextCycle.h
    src/lib/trace/TextTrace.cpp
    src/lib/trace/TextTrace.h
    src/lib/trace/TraceBinaryMemoryReader.cpp
    src/lib/trace/TraceBinaryMemoryWriter.cpp
    src/lib/trace/TraceBinaryReader.cpp
    src/lib/trace/TraceBinaryWriter.cpp
    src/lib/trace/TraceIndexReader.cpp
    src/lib/trace/TraceIndexWriter.cpp
    src/lib/trace/TraceJsonPrinter.cpp
    src/lib/trace/TracePcPrinter.cpp
    src/lib/trace/TraceTextPrinter.cpp
    src/lib/trace/TraceTextReader.cpp
)

# =========================================================================
# librafi_emu
#
add_library(librafi_emu
    include/rafi/emu.h
    include/rafi/emu/BasicTypes.h
    include/rafi/emu/Bus.h
    include/rafi/emu/IInterruptSource.h
    include/rafi/emu/IIo.h
    include/rafi/emu/IMemory.h
    include/rafi/emu/Macro.h
    include/rafi/emu/Rom.h
    include/rafi/emu/Ram.h
    src/lib/emu/Bus.cpp
    src/lib/emu/Ram.cpp
    src/lib/emu/Rom.cpp
)

# =========================================================================
# rafi-check-io
#
add_executable(rafi-check-io
    src/bin/rafi-check-io/Main.cpp
    src/bin/util/TraceUtil.cpp
    src/bin/util/TraceUtil.h
)

include_directories(rafi-check-io include)

target_link_libraries(rafi-check-io
    librafi_trace
    librafi_common
    ${Boost_LIBRARIES}
    ${FS_LIBRARIES}
)

# =========================================================================
# rafi-conv
#
add_executable(rafi-conv
    src/bin/rafi-conv/Main.cpp
    src/bin/util/TraceUtil.cpp
    src/bin/util/TraceUtil.h
)

include_directories(rafi-conv include)

target_link_libraries(rafi-conv
    librafi_trace
    librafi_common
    ${Boost_LIBRARIES}
    ${FS_LIBRARIES}
)

# =========================================================================
# rafi-diff
#
add_executable(rafi-diff
    src/bin/rafi-diff/Main.cpp
    src/bin/rafi-diff/CommandLineOption.cpp
    src/bin/rafi-diff/CommandLineOption.h
    src/bin/rafi-diff/CycleComparator.cpp
    src/bin/rafi-diff/CycleComparator.h
    src/bin/util/TraceUtil.cpp
    src/bin/util/TraceUtil.h
)

include_directories(rafi-diff include)

target_link_libraries(rafi-diff
    librafi_trace
    librafi_common
    ${Boost_LIBRARIES}
    ${FS_LIBRARIES}
)

# =========================================================================
# rafi-dump
#
add_executable(rafi-dump
    src/bin/rafi-dump/CommandLineOption.cpp
    src/bin/rafi-dump/CommandLineOption.h
    src/bin/rafi-dump/CycleFilter.cpp
    src/bin/rafi-dump/CycleFilter.h
    src/bin/rafi-dump/Main.cpp
    src/bin/util/TraceUtil.cpp
    src/bin/util/TraceUtil.h
)

include_directories(rafi-dump include)

target_link_libraries(rafi-dump
    librafi_trace
    librafi_common
    ${Boost_LIBRARIES}
    ${FS_LIBRARIES}
)

# =========================================================================
# rafi-emu
#
add_executable(rafi-emu
    src/bin/rafi-emu/cpu/AtomicManager.cpp
    src/bin/rafi-emu/cpu/AtomicManager.h
    src/bin/rafi-emu/cpu/Csr.cpp
    src/bin/rafi-emu/cpu/Csr.h
    src/bin/rafi-emu/cpu/Executor.cpp
    src/bin/rafi-emu/cpu/Executor.h
    src/bin/rafi-emu/cpu/FpRegFile.cpp
    src/bin/rafi-emu/cpu/FpRegFile.h
    src/bin/rafi-emu/cpu/InterruptController.cpp
    src/bin/rafi-emu/cpu/InterruptController.h
    src/bin/rafi-emu/cpu/IntRegFile.cpp
    src/bin/rafi-emu/cpu/IntRegFile.h
    src/bin/rafi-emu/cpu/MemoryAccessUnit.cpp
    src/bin/rafi-emu/cpu/MemoryAccessUnit.h
    src/bin/rafi-emu/cpu/Processor.cpp
    src/bin/rafi-emu/cpu/Processor.h
    src/bin/rafi-emu/cpu/Trap.cpp
    src/bin/rafi-emu/cpu/Trap.h
    src/bin/rafi-emu/cpu/TrapProcessor.cpp
    src/bin/rafi-emu/cpu/TrapProcessor.h
    src/bin/rafi-emu/gdb/GdbCommandFactory.cpp
    src/bin/rafi-emu/gdb/GdbCommandFactory.h
    src/bin/rafi-emu/gdb/GdbCommands.cpp
    src/bin/rafi-emu/gdb/GdbCommands.h
    src/bin/rafi-emu/gdb/GdbData.cpp
    src/bin/rafi-emu/gdb/GdbData.h
    src/bin/rafi-emu/gdb/GdbException.h
    src/bin/rafi-emu/gdb/GdbTypes.h
    src/bin/rafi-emu/gdb/GdbServer.cpp
    src/bin/rafi-emu/gdb/GdbServer.h
    src/bin/rafi-emu/gdb/GdbUtil.cpp
    src/bin/rafi-emu/gdb/GdbUtil.h
    src/bin/rafi-emu/io/Clint.cpp
    src/bin/rafi-emu/io/Clint.h
    src/bin/rafi-emu/io/IoInterruptSource.cpp
    src/bin/rafi-emu/io/IoInterruptSource.h
    src/bin/rafi-emu/io/Plic.cpp
    src/bin/rafi-emu/io/Plic.h
    src/bin/rafi-emu/io/Uart.cpp
    src/bin/rafi-emu/io/Uart.h
    src/bin/rafi-emu/io/Uart16550.cpp
    src/bin/rafi-emu/io/Uart16550.h
    src/bin/rafi-emu/io/Timer.cpp
    src/bin/rafi-emu/io/Timer.h
    src/bin/rafi-emu/io/VirtIo.cpp
    src/bin/rafi-emu/io/VirtIo.h
    src/bin/rafi-emu/CommandLineOption.cpp
    src/bin/rafi-emu/CommandLineOption.h
    src/bin/rafi-emu/Emulator.cpp
    src/bin/rafi-emu/Emulator.h
    src/bin/rafi-emu/IEmulator.h
    src/bin/rafi-emu/Main.cpp
    src/bin/rafi-emu/Socket.cpp
    src/bin/rafi-emu/Socket.h
    src/bin/rafi-emu/System.cpp
    src/bin/rafi-emu/System.h
)

include_directories(rafi-emu include)

target_link_libraries(rafi-emu
    librafi_emu
    librafi_fp
    librafi_trace
    librafi_common
    ${Boost_LIBRARIES}
    ${FS_LIBRARIES}
    ${Socket_LIBRARIES}
)

# =========================================================================
# rafi-emu-test
#
add_executable(rafi-emu-test
    src/bin/rafi-emu/gdb/GdbCommandFactory.cpp
    src/bin/rafi-emu/gdb/GdbCommandFactory.h
    src/bin/rafi-emu/gdb/GdbCommands.cpp
    src/bin/rafi-emu/gdb/GdbCommands.h
    src/bin/rafi-emu/gdb/GdbData.cpp
    src/bin/rafi-emu/gdb/GdbData.h
    src/bin/rafi-emu/gdb/GdbException.h
    src/bin/rafi-emu/gdb/GdbTypes.h
    src/bin/rafi-emu/gdb/GdbUtil.cpp
    src/bin/rafi-emu/gdb/GdbUtil.h
    src/bin/rafi-emu-test/GdbTest.cpp
    src/bin/rafi-emu-test/OpGetStringTest.cpp
    src/bin/rafi-emu-test/StubEmulator.cpp
    src/bin/rafi-emu-test/StubEmulator.h
    src/bin/rafi-emu-test/TextTraceTest.cpp
)

include_directories(rafi-emu-test include)

target_link_libraries(rafi-emu-test
    librafi_trace
    librafi_common
    ${GoogleTest_LIBRARIES}
)

if (verilator_FOUND)
    # =========================================================================
    # rafi-sim
    #
    add_executable(rafi-sim
        src/bin/rafi-sim/CommandLineOption.cpp
        src/bin/rafi-sim/CommandLineOption.h
        src/bin/rafi-sim/Main.cpp
        src/bin/rafi-sim/Simulator.cpp
        src/bin/rafi-sim/Simulator.h
        src/bin/rafi-sim/System.cpp
        src/bin/rafi-sim/System.h
    )

    verilate(rafi-sim
        PREFIX VCore
        THREADS 1
        TRACE
        SOURCES
        src/hw/def/BasicTypes.sv
        src/hw/def/Rv32Types.sv
        src/hw/def/RvTypes.sv
        src/hw/def/TlbTypes.sv
        src/hw/def/ProcessorTypes.sv
        src/hw/def/CacheTypes.sv
        src/hw/def/MemoryTypes.sv
        src/hw/def/OpTypes.sv
        src/hw/def/Decoder.sv
        src/hw/def/LoadStoreUnitTypes.sv
        src/hw/div/DivUnit.sv
        src/hw/mul/MulUnit.sv
        src/hw/core/BlockRam.sv
        src/hw/core/FlipFlopCam.sv
        src/hw/core/Tlb.sv
        src/hw/core/TlbReplacer.sv
        src/hw/core/ResetSequencer.sv
        src/hw/core/FetchUnit.sv
        src/hw/core/FetchUnitIF.sv
        src/hw/core/ICacheInvalidater.sv
        src/hw/core/ICacheReplacer.sv
        src/hw/core/DCacheReplacer.sv
        src/hw/core/LoadStoreUnitIF.sv
        src/hw/core/LoadStoreUnit.sv
        src/hw/core/BusAccessUnit.sv
        src/hw/core/BusAccessUnitIF.sv
        src/hw/core/BypassLogic.sv
        src/hw/core/BypassLogicIF.sv
        src/hw/core/ControlStatusRegister.sv
        src/hw/core/ControlStatusRegisterIF.sv
        src/hw/core/DecodeStage.sv
        src/hw/core/DecodeStageIF.sv
        src/hw/core/ExecuteStage.sv
        src/hw/core/ExecuteStageIF.sv
        src/hw/core/FetchStage.sv
        src/hw/core/FetchStageIF.sv
        src/hw/core/MemoryAccessStage.sv
        src/hw/core/MemoryAccessStageIF.sv
        src/hw/core/PipelineController.sv
        src/hw/core/PipelineControllerIF.sv
        src/hw/core/RegFile.sv
        src/hw/core/RegFileIF.sv
        src/hw/core/RegReadStage.sv
        src/hw/core/RegReadStageIF.sv
        src/hw/core/RegWriteStage.sv
        src/hw/core/Core.sv
    )

    include_directories(rafi-sim include)

    # disable warnings for verilator
    if (MSVC)
        target_compile_options(rafi-sim
            PUBLIC /wd"4018"
            PUBLIC /wd"4267"
            PUBLIC /wd"4273"
        )
    endif()

    target_link_libraries(rafi-sim
        PRIVATE librafi_emu
        PRIVATE librafi_fp
        PRIVATE librafi_trace
        PRIVATE librafi_common
        PRIVATE ${Boost_LIBRARIES}
        PRIVATE ${FS_LIBRARIES}
    )

    # =========================================================================
    # rafi-vtest-mul
    #
    add_executable(rafi-vtest-mul
        src/hw/mul/MulUnitTest.cpp
    )
    verilate(rafi-vtest-mul
        PREFIX VMulUnit
        THREADS 1
        TRACE
        SOURCES
        src/hw/def/BasicTypes.sv
        src/hw/def/RvTypes.sv
        src/hw/def/Rv32Types.sv
        src/hw/mul/MulUnit.sv
    )
    target_link_libraries(rafi-vtest-mul
        PRIVATE ${GoogleTest_LIBRARIES}
    )

    # disable warnings for verilator
    if (MSVC)
        target_compile_options(rafi-vtest-mul
            PUBLIC /wd"4267"
        )
    endif()

    # =========================================================================
    # rafi-vtest-timer
    #
    add_executable(rafi-vtest-timer
        src/hw/timer/TimerTest.cpp
    )
    verilate(rafi-vtest-timer
        SOURCES src/hw/timer/Timer.sv
    )
    target_link_libraries(rafi-vtest-timer
        PRIVATE ${GoogleTest_LIBRARIES}
    )

    # disable warnings for verilator
    if (MSVC)
        target_compile_options(rafi-vtest-timer
            PUBLIC /wd"4267"
        )
    endif()
else()
  message(WARNING "Verilator was not found. Skip building SystemVerilog codes")
endif()
