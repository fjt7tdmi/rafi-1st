cmake_minimum_required(VERSION 3.8)

enable_language(CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include_directories(~/local/share/verilator/include)
include_directories(~/local/share/verilator/include/vltstd)

add_executable(test_Core
    ~/local/share/verilator/include/verilated.cpp
    work/verilator/test_Core/VCore__Syms.cpp
	work/verilator/test_Core/VCore.cpp
	work/verilator/test_Core/VCore___024unit.cpp
	work/verilator/test_Core/VCore_FetchUnitIF.cpp
	work/verilator/test_Core/VCore_LoadStoreUnitIF.cpp
	work/verilator/test_Core/VCore_MemoryAccessArbiterIF__L10_A1e.cpp
	work/verilator/test_Core/VCore_BypassLogicIF.cpp
	work/verilator/test_Core/VCore_ControlStatusRegisterIF.cpp
	work/verilator/test_Core/VCore_DecodeStageIF.cpp
	work/verilator/test_Core/VCore_ExecuteStageIF.cpp
	work/verilator/test_Core/VCore_FetchStageIF.cpp
	work/verilator/test_Core/VCore_MemoryAccessStageIF.cpp
	work/verilator/test_Core/VCore_PipelineControllerIF.cpp
	work/verilator/test_Core/VCore_RegFileIF.cpp
	work/verilator/test_Core/VCore_RegReadStageIF
    cpu/test/test_Core.cpp
)

add_executable(test_Timer
    ~/local/share/verilator/include/verilated.cpp
    work/verilator/test_Timer/VTimer__Syms.cpp
    work/verilator/test_Timer/VTimer.cpp
    module/Timer/test/test_Timer.cpp
)
