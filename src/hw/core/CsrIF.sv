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

interface CsrIF;
    addr_t nextPc;

    word_t readValue;
    csr_addr_t readAddr;
    logic readEnable;
    logic readIllegal;

    csr_satp_t satp;
    csr_xstatus_t mstatus;
    Privilege privilege;
    logic trapSupervisorReturn;

    word_t writeValue;
    csr_addr_t writeAddr;
    logic writeEnable;

    TrapInfo trapInfo;
    addr_t trapPc;
    logic trapReturn;
    Privilege trapReturnPrivilege;

    modport Csr(
    output
        nextPc,
        readValue,
        readIllegal,
        satp,
        mstatus,
        privilege,
        trapSupervisorReturn,
    input
        readAddr,
        readEnable,
        writeValue,
        writeAddr,
        writeEnable,
        trapInfo,
        trapPc,
        trapReturn,
        trapReturnPrivilege
    );

    modport FetchUnit(
    input
        nextPc,
        satp,
        mstatus,
        privilege,
        trapInfo,
        trapReturn
    );

    modport LoadStoreUnit(
    input
        nextPc,
        satp,
        mstatus,
        privilege,
        trapInfo
    );

    modport FetchStage(
    input
        nextPc,
        trapInfo
    );

    modport ExecuteStage(
    output
        readAddr,
        readEnable,
    input
        privilege,
        trapSupervisorReturn,
        readValue,
        readIllegal
    );

    modport RegWriteStage(
    output
        writeValue,
        writeAddr,
        writeEnable,
        trapInfo,
        trapPc,
        trapReturn,
        trapReturnPrivilege
    );
endinterface
