cmake_minimum_required(VERSION 3.8)

enable_language(CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include_directories(C:/home/Programs/verilator-3.841/include)
include_directories(C:/home/Programs/verilator-3.841/include/vltstd)

add_executable(testTimer
    C:/home/Programs/verilator-3.841/include/verilated.cpp
    Modules/Timer/obj_dir/VTimer__Syms.cpp
    Modules/Timer/obj_dir/VTimer.cpp
    Modules/Timer/test/testTimer.cpp
)
