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
    addr_t addr;
    logic done;
    logic enable;
    logic invalidateTlb;
    LoadStoreUnitCommand command;
    LoadStoreType loadStoreType;
    AtomicType atomicType;
    uint64_t result;
    uint64_t storeRegValue;

    logic loadPagefault;
    logic storePagefault;

    modport ExecuteStage(
    output
        addr,
        enable,
        invalidateTlb,
        command,
        loadStoreType,
        atomicType,
        storeRegValue,
    input
        done,
        loadPagefault,
        storePagefault,
        result
    );

    modport LoadStoreUnit(
    output
        done,
        loadPagefault,
        storePagefault,
        result,
    input
        addr,
        enable,
        invalidateTlb,
        command,
        loadStoreType,
        atomicType,
        storeRegValue
    );
endinterface
