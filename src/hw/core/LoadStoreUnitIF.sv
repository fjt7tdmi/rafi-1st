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

import OpTypes::*;

interface LoadStoreUnitIF;
    logic done;
    logic enable;
    logic invalidateTlb;
    logic loadPagefault;
    logic storePagefault;
    addr_t resultAddr;
    uint64_t resultValue;

    LoadStoreUnitCommand loadStoreUnitCommand;
    MemUnitCommand command;
    word_t imm;
    word_t srcIntRegValue1;
    word_t srcIntRegValue2;
    uint64_t srcFpRegValue2;

    modport ExecuteStage(
    output
        enable,
        invalidateTlb,
        loadStoreUnitCommand,
        command,
        imm,
        srcIntRegValue1,
        srcIntRegValue2,
        srcFpRegValue2,
    input
        done,
        loadPagefault,
        storePagefault,
        resultAddr,
        resultValue
    );

    modport LoadStoreUnit(
    output
        done,
        loadPagefault,
        storePagefault,
        resultAddr,
        resultValue,
    input
        enable,
        invalidateTlb,
        loadStoreUnitCommand,
        command,
        imm,
        srcIntRegValue1,
        srcIntRegValue2,
        srcFpRegValue2
    );
endinterface
