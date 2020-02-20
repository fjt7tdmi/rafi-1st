/*
 * Copyright 2018 Akifumi Fujita
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

import ProcessorTypes::*;

interface InsnBufferIF;
    insn_buffer_entry_count_t writableEntryCount;
    insn_buffer_entry_count_t readableEntryCount;

    logic writeLow;
    logic writeHigh;
    logic readLow;
    logic readHigh;

    InsnBufferEntry writeEntryLow;
    InsnBufferEntry writeEntryHigh;
    InsnBufferEntry readEntryLow;
    InsnBufferEntry readEntryHigh;

    modport InsnBuffer(
    output
        readableEntryCount,
        writableEntryCount,
        readEntryLow,
        readEntryHigh,
    input
        readLow,
        readHigh,
        writeLow,
        writeHigh,
        writeEntryLow,
        writeEntryHigh);

    modport FetchStage(
    output
        writeLow,
        writeHigh,
        writeEntryLow,
        writeEntryHigh,
    input
        writableEntryCount);

    modport DecodeStage(
    output
        readLow,
        readHigh,
    input
        readableEntryCount,
        readEntryLow,
        readEntryHigh);

endinterface
