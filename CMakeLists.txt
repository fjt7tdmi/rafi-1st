cmake_minimum_required(VERSION 3.8)

enable_language(CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_subdirectory(rafi-emu)

find_package(Boost)

if (NOT ${Boost_FOUND})
    message(FATAL_ERROR "Cannot find boost.")
endif()

include_directories(${Boost_INCLUDE_DIRS})
include_directories(~/local/share/verilator/include)
include_directories(~/local/share/verilator/include/vltstd)
include_directories(rafi-emu/include)

link_directories(${Boost_LIBRARY_DIRS})

set(Boost_LIBRARIES "boost_program_options")

add_executable(test_Core
    ~/local/share/verilator/include/verilated.cpp
    ~/local/share/verilator/include/verilated_vcd_c.cpp
    work/verilator/test_Core/VCore__Syms.cpp
	work/verilator/test_Core/VCore__Trace.cpp
	work/verilator/test_Core/VCore__Trace__Slow.cpp
	work/verilator/test_Core/VCore.cpp
	work/verilator/test_Core/VCore_Core.cpp
	work/verilator/test_Core/VCore___024unit.cpp
	work/verilator/test_Core/VCore_RegFile.cpp
	work/verilator/test_Core/VCore_RegWriteStage.cpp
	work/verilator/test_Core/VCore_FetchUnitIF.cpp
	work/verilator/test_Core/VCore_LoadStoreUnitIF.cpp
	work/verilator/test_Core/VCore_BusAccessUnitIF.cpp
	work/verilator/test_Core/VCore_BypassLogicIF.cpp
	work/verilator/test_Core/VCore_ControlStatusRegisterIF.cpp
	work/verilator/test_Core/VCore_DecodeStageIF.cpp
	work/verilator/test_Core/VCore_ExecuteStageIF.cpp
	work/verilator/test_Core/VCore_FetchStageIF.cpp
	work/verilator/test_Core/VCore_MemoryAccessStageIF.cpp
	work/verilator/test_Core/VCore_PipelineControllerIF.cpp
	work/verilator/test_Core/VCore_RegFileIF.cpp
	work/verilator/test_Core/VCore_RegReadStageIF.cpp
    cpu/test/Core/Dumper.cpp
    cpu/test/Core/Dumper.h
    cpu/test/Core/Main.cpp
    cpu/test/Core/Memory.cpp
    cpu/test/Core/Memory.h
    cpu/test/Core/Option.cpp
    cpu/test/Core/Option.h
)

add_executable(test_Timer
    ~/local/share/verilator/include/verilated.cpp
    ~/local/share/verilator/include/verilated_vcd_c.cpp
    work/verilator/test_Timer/VTimer__Syms.cpp
    work/verilator/test_Timer/VTimer__Syms.h
    work/verilator/test_Timer/VTimer__Trace__Slow.cpp
    work/verilator/test_Timer/VTimer__Trace.cpp
    work/verilator/test_Timer/VTimer.cpp
    work/verilator/test_Timer/VTimer.h
    module/Timer/test/test_Timer.cpp
)

add_executable(test_DivUnit
    ~/local/share/verilator/include/verilated.cpp
    ~/local/share/verilator/include/verilated_vcd_c.cpp
    work/verilator/test_DivUnit/VDivUnit32__Syms.cpp
    work/verilator/test_DivUnit/VDivUnit32__Syms.h
    work/verilator/test_DivUnit/VDivUnit32__Trace__Slow.cpp
    work/verilator/test_DivUnit/VDivUnit32__Trace.cpp
    work/verilator/test_DivUnit/VDivUnit32__Syms.cpp
    work/verilator/test_DivUnit/VDivUnit32.cpp
    work/verilator/test_DivUnit/VDivUnit32.h
    module/DivUnit/test/test_DivUnit.cpp
)

target_link_libraries(test_Core librvtrace ${Boost_LIBRARIES})
