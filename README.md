# RAFI

RAFI (RISCV Akifumi Fujita Implementation) is my hobby project to make a RISCV processor.
This repository includes C++ emulator and SystemVerilog HDL implementation.

* ![](https://github.com/fjt7tdmi/rafi-1st/workflows/run-test/badge.svg)
* ![](https://github.com/fjt7tdmi/rafi-1st/workflows/run-verilator/badge.svg)

## Progress of implementation

|Feature      |C++ Emulator|SystemVerilog|
|-------------|------------|-------------|
|RV32I        |Done        |WIP          |
|RV32M        |Done        |-            |
|RV32A        |Done        |-            |
|RV32F        |Done        |-            |
|RV32D        |Done        |-            |
|RV32C        |Done        |-            |
|RV32 priv.   |Done        |-            |
|RV64I        |Done        |-            |
|RV64M        |Done        |-            |
|RV64A        |Done        |-            |
|RV64F        |Done        |-            |
|RV64D        |Done        |-            |
|RV64C        |Done        |-            |
|RV64 priv.   |Done        |-            |
|Linux support|WIP         |-            |

## Supported development environment

* MSYS2 on Windows 10
* Ubuntu 18.04

## How to develop

### Install required modules

#### Windows 10

Install the following programs manually.

* MSYS2
* Visual Studio 2019
* Boost (>= 1.65)
* CMake (>= 3.8)
* Ninja
* Python (>= 3.6)
* Verilator

#### Ubuntu 18.04
```
apt-get install \
    libboost-filesystem1.65.1 libboost-program-options1.65.1 libboost1.65-dev \
    cmake \
    ninja-build \
    python \
    verilator
```

### Build emulator
```
# Build googletest in git submodule
./script/build_gtest.sh

# Debug build
./script/build_debug.sh

# Release build
./script/build_release.sh
```

## Run unit test of emulator
```
./script/run_emu_test.sh
```

## How to run riscv-tests and linux on emulator

First, it's necessary to checkout prebuilt binaries.
However, the prebuilt binaries repository is private because of a license issue now (Jan 2020).
Sorry!

```
./script/checkout_prebuilt_binary.sh
```

Then, run riscv-tests or linux.

```
# Run riscv-tests
./script/run_emu_riscv_tests.sh

# Boot linux (it will halt while running /init because of my bug :P)
./script/run_emu_linux.sh
```

## Run HDL simulation by verilator
WIP
