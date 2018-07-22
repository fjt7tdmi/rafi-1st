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

package LoadStoreUnitTypes;

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

// ----------------------------------------------------------------------------
// parameter

// ----------------------------------------------------------------------------
// typedef

typedef enum logic [2:0]
{
    LoadStoreUnitCommand_None               = 3'h0,
    LoadStoreUnitCommand_Load               = 3'h1,
    LoadStoreUnitCommand_Store              = 3'h2,
    LoadStoreUnitCommand_Invalidate         = 3'h3,
    LoadStoreUnitCommand_AtomicMemOp        = 3'h4,
    LoadStoreUnitCommand_LoadReserved       = 3'h5,
    LoadStoreUnitCommand_StoreConditional   = 3'h6
} LoadStoreUnitCommand;

// ----------------------------------------------------------------------------

endpackage
