#!/bin/bash

OPTION=""
if [ $# -ge 1 ]; then
    OPTION="-f $1"
fi

# Move to project top directory
cd `dirname $0`
cd ..

 ./rafi-emu/Release/RafiEmu.exe \
    --binary ./Work/vmlinux.bin:0xc0000000 \
    --binary ./DeviceTrees/rafi.dtb:0xc0700000 \
    --cycle 4000000 \
    --dtb-address 0xc0700000 \
    --dump-path ./Work/Trace/Emulator/linux.trace.bin \
    --dump-skip-cycle 3000000 \
    --pc 0xc0000000
