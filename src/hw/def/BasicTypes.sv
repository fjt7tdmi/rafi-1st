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

package BasicTypes;

// Bit width
parameter BYTE_WIDTH = 8;

// typedef
typedef logic signed [7:0]  int8_t;
typedef logic signed [15:0] int16_t;
typedef logic signed [31:0] int32_t;
typedef logic signed [63:0] int64_t;

typedef logic [7:0]  uint8_t;
typedef logic [15:0] uint16_t;
typedef logic [31:0] uint32_t;
typedef logic [63:0] uint64_t;

typedef struct packed {
    logic sign;
    logic [7:0] exponent;
    logic [22:0] fraction;
} fp32_t;

endpackage
