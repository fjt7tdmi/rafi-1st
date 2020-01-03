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

package MemoryTypes;

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

// parameter
parameter UartAddr      = 34'h040000000;
parameter HostIoAddr    = 34'h080001000;

parameter MemoryAddrBegin   = 34'h080000000;
parameter MemoryAddrEnd     = 34'h100000000;
endpackage
