cmake_minimum_required(VERSION 3.8)

enable_language(CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include_directories(C:/home/Programs/verilator-3.841/include)
include_directories(C:/home/Programs/verilator-3.841/include/vltstd)

add_executable(test_Timer
    C:/home/Programs/verilator-3.841/include/verilated.cpp
    work/verilator/test_Timer/VTimer__Syms.cpp
    work/verilator/test_Timer/VTimer.cpp
    work/verilator/test_Timer/test/test_Timer.cpp
)
