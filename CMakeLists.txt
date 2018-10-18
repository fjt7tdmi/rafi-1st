cmake_minimum_required(VERSION 3.8)

enable_language(CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# include_directories(ENV{VERILATOR_BASE}/include)
include_directories(C:/home/Programs/verilator-3.841/include)
include_directories(C:/home/Programs/verilator-3.841/include/vltstd)

add_executable(testTimer
    C:/home/Programs/verilator-3.841/include/verilated.cpp
    C:/home/Programs/verilator-3.841/include/verilated_dpi.cpp
    C:/home/Programs/verilator-3.841/include/verilated_save.cpp
    C:/home/Programs/verilator-3.841/include/verilated_vcd_c.cpp
    C:/home/Programs/verilator-3.841/include/verilated_vcd_sc.cpp
    C:/home/Programs/verilator-3.841/include/verilated_vpi.cpp
    Modules/Timer/obj_dir/VTimer__Syms.cpp
    Modules/Timer/obj_dir/VTimer.cpp
    Modules/Timer/test/testTimer.cpp
)
