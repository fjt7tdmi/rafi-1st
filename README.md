# RAFI

RAFI (RISCV Akifumi Fujita Implementation) is my hobby project to make a RISCV processor.
This repository includes C++ emulator and SystemVerilog HDL implementation.

* ![](https://github.com/fjt7tdmi/rafi-1st/workflows/run-test/badge.svg)

## Progress of implementation

|Feature      |C++ Emulator|SystemVerilog|
|-------------|------------|-------------|
|RV32I        |Done        |Done         |
|RV32M        |Done        |Done         |
|RV32A        |Done        |-            |
|RV32F        |Done        |-            |
|RV32D        |Done        |-            |
|RV32C        |Done        |-            |
|RV32 priv.   |Done        |WIP          |
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
* CMake (>= 3.16)
* Ninja
* Python (>= 3.6)
* Verilator (>= 4.024)

#### Ubuntu 18.04
```
apt-get install \
    libboost-filesystem1.65.1 libboost-program-options1.65.1 libboost1.65-dev \
    cmake \
    ninja-build \
    python
```

* Verilator (>= 4.024)
  * Manual build and install are required.

### Build
```
# Build googletest in git submodule
./script/build_gtest.sh

# Debug build
./script/build_debug.sh

# Release build
./script/build_release.sh
```

### Run unit test
```
./script/run_emu_test.sh
```

### Run HDL verification by verilator
```
./script/run_vtest.sh
```

### Run riscv-tests and linux

First, it's necessary to checkout prebuilt binaries.
However, the prebuilt binaries repository is private because of a license issue now (Jan 2020).
Sorry!

```
./script/checkout_prebuilt_binary.sh
```

Then, run riscv-tests or linux.

#### On C++ emulator

```
# Run riscv-tests
./script/run_emu_riscv_tests.sh

# Boot linux (it will halt while running /init because of my bug :P)
./script/run_emu_linux.sh
```

#### HDL emulation

```
# Run riscv-tests
./script/run_sim_riscv_tests.sh
```

HDL implementation does not support booting linux now.
