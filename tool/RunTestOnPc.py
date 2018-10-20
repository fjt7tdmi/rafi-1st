# Copyright 2018 Akifumi Fujita
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import fnmatch
import json
import multiprocessing
import optparse
import os
import subprocess

from functools import reduce
from operator import or_

DefaultTestCycle = 65536
CheckIoPath = "./rafi-emu/Release/CheckIo.exe"
EmulatorPath = "./rafi-emu/Release/RafiEmu.exe"
BinaryDirPath = "./firmware/Outputs"
TraceDirPath = "./work/Trace"

#
# Functions
#
def CleanDirectory(dirname):
    for filename in os.listdir(f"{TraceDirPath}/{dirname}"):
        os.remove(f"{TraceDirPath}/{dirname}/{filename}")

def MakeCheckIoCommand(trace_paths):
    cmd = [CheckIoPath]
    cmd.extend(trace_paths)
    return cmd

def MakeEmulatorCommand(testname):
    binary_path = f"{BinaryDirPath}/{testname}.bin"
    trace_path = f"{TraceDirPath}/Emulator/{testname}.trace.bin"
    return [
        EmulatorPath,
        "--cycle", str(DefaultTestCycle),
        "--binary", binary_path,
        "--dump-path", trace_path,
        "--stop-by-host-io",
    ]

def MakeSimulatorCommand(testname, cycle, all_dump):
    initial_memory_path = f"{BinaryDirPath}/{testname}.txt"
    dump_path = f"{TraceDirPath}/cpu/{testname}.trace.bin"
    enable_dump_memory = "1" if all_dump else "0"
    project = "SystemTest"
    return [
        'vsim', project,
        '-c',
        '-lib', project,
        '-do', 'run -all',
        '-G', f'INITIAL_MEMORY_PATH="../../../../{initial_memory_path}"',
        '-G', f'DUMP_PATH="../../../../{dump_path}"',
        '-G', f'SIMULATION_CYCLE={cycle}',
        '-G', f'ENABLE_DUMP_CSR=0',
        '-G', f'ENABLE_DUMP_MEMORY={enable_dump_memory}',
        '-G', 'ENABLE_FINISH=1',
    ]

def CheckSimulatorLog(path):
    keyword = "Error:"

    if not os.path.exists(path):
        return (False, f"File not found.")

    with open(path, "r") as f:
        lines = f.readlines()
        errorFlags = list(map(lambda line: keyword in line, lines))

        errorLog = ""
        for i in range(1, len(lines)):
            if errorFlags[i-1] or errorFlags[i]:
                errorLog += lines[i]

        error = reduce(or_, errorFlags)
        return (error, errorLog)

def VerifyTraces(paths):
    cmd = MakeCheckIoCommand(paths)
    print(f"Run {' '.join(cmd)}")

    subprocess.run(cmd)

def RunEmulator(setting):
    testname = setting[0]["name"]
    all_dump = setting[1]

    cmd = MakeEmulatorCommand(testname)
    print(f"Run {' '.join(cmd)}")

    result = subprocess.run(cmd)
    if result.returncode != 0:
        return False # Emulation Failure

def RunSimulator(setting):
    testname = setting[0]["name"]
    cycle = setting[0]["cycle"]
    all_dump = setting[1]
    processor = setting[2]

    cmd = MakeSimulatorCommand(testname, cycle, all_dump)
    print(f"Run {' '.join(cmd)}")

    logPath = f"{TraceDirPath}/cpu/{testname}.vsim.log"

    result = None
    with open(logPath, "w") as f:
        result = subprocess.run(cmd, cwd=f"work/ModelSim/Processor", stdout=f)

    if result.returncode != 0:
        print(f"Simulator program returns error. (code = {result.returncode})")
        return False

    (error, errorLog) = CheckSimulatorLog(logPath)
    if error:
        print(f"Error found while checking '{logPath}'")
        print(errorLog)
        return False

    return True

def RunTests(configs, all_dump, isEmulator, processor = None):
    if isEmulator:
        with multiprocessing.Pool(multiprocessing.cpu_count()) as p:
            settings = list(map(lambda config: (config, all_dump), configs))
            results = p.map(RunEmulator, settings)
        VerifyTraces(list(map(lambda config: f"{TraceDirPath}/Emulator/{config['name']}.trace.bin", configs)))
    else:
        with multiprocessing.Pool(multiprocessing.cpu_count()) as p:
            settings = list(map(lambda config: (config, all_dump, processor), configs))
            results = p.map(RunSimulator, settings)
        VerifyTraces(list(map(lambda config: f"{TraceDirPath}/cpu/{config['name']}.trace.bin", configs)))
    # TODO: Handle Emulation/Simulation Failure

#
# Entry point
#
if __name__ == '__main__':
    parser = optparse.OptionParser()
    parser.add_option("-a", dest="all_dump", action="store_true", default=False, help="Enable memory dump and csr dump.")
    parser.add_option("-f", dest="filter", default=None, help="Filter test by name.")
    parser.add_option("-i", dest="input_path", default=None, help="Input test list json path.")
    parser.add_option("-l", dest="list_tests", action="store_true", default=False, help="List test names.")
    parser.add_option("-e", dest="emulator", action="store_true", default=False, help="Run tests on emulator.")
    parser.add_option("-s", dest="simulator", action="store_true", default=[], help="Run tests on simulator.")

    (options, args) = parser.parse_args()

    if options.input_path is None:
        print("Input test list json is not specified.")
        exit(1)

    if options.emulator == False and options.simulator == 0:
        print("Neither processor nor emulator is specified.")
        exit(1)

    configs = []

    with open(options.input_path, "r") as f:
        configs = json.load(f)

    if options.list_tests:
        for config in configs:
            print(config['name'])
        exit(0)

    if options.filter is not None:
        configs = list(filter(lambda config: fnmatch.fnmatch(config["name"], options.filter), configs))

    if options.emulator == True:
        print("-------------------------------------------------------------")
        print("Run test on emulator:")
        CleanDirectory("Emulator")
        RunTests(configs, options.all_dump, True)

    if options.simulator == True:
        print("-------------------------------------------------------------")
        print("Run test on simulator:")
        CleanDirectory("Simulator")
        RunTests(configs, options.all_dump, True)
