#!/bin/bash

# Move to project top directory
cd `dirname $0`
cd ..

#echo "PrintTrace"
#./rafi-emu/Release/PrintTrace.exe $@ ./Work/Trace/Emulator/linux.trace.bin > ./Work/Trace/Emulator/linux.trace.txt

echo "DumpPc"
./rafi-emu/Release/DumpPc.exe $@ ./Work/Trace/Emulator/linux.trace.bin > ./Work/Trace/Emulator/linux.pc.txt

echo "addr2line"
riscv64-unknown-elf-addr2line -a -f -e ./Linux/vmlinux < ./Work/Trace/Emulator/linux.pc.txt > ./Work/Trace/Emulator/linux.addr2line.txt
